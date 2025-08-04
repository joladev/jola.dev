%{
  title: "Patterns for managing ETS tables",
  author: "Johanna Larsson",
  tags: ~w(ets erlang elixir),
  description: "This article attempts to show some basic patterns for how to use ETS in Elixir or Erlang"
}
---
This article attempts to show some basic patterns for how to use ETS in Elixir or Erlang, working around the limitations and giving you some examples of how to use them effectively in your own codebase. The intended audience is someone interested in using ETS but unsure of where to put the table and how to manage it. Note that none of the examples are “complete”, although each of them attempts to showcase key concepts in the logistics and use of ETS, none of them are just ready to copy paste into your project. They’re over-simplified to make them more accessible and each one just demonstrates some features. This is more of a learning exercise than anything else. By necessity, the article also touches on the subject of concurrency in Elixir (and ironically, how to “avoid” it).

ETS is a really cool tool in the Erlang runtime system, but to understand it you may need a little context. I won’t go too deep into how it works, but even a very short explanation of it starts with a description of the memory management of the BEAM. In short, every single line of Elixir or Erlang runs in a process and each process has its own heap. This provides all kinds of cool properties for your code: including sidestepping problems of shared memory access and making garbage collection cheap by limiting it per process (since the heap is automatically freed by processes that end, sometimes you don’t even necessarily get any overhead from garbage collection). But if every process owns its own heap and is unable to access any other’s, how can they share data?

One way is sending messages, which means copying it from one heap to another. This is what you do if you communicate across processes. Let’s take [Agents](https://elixir-lang.org/getting-started/mix-otp/agent.html) as an example. Each agent stores its own state and accepts requests to get or update that data. Any data you get out of an Agent is copied to the requesting process. There are downsides to storing data in processes though, you are not able to access it concurrently. The process holding the data acts as a bottle-neck. This in and of It also generally keeps its state in a standard immutable Elixir data structure. Immutable data structures are really cool, but as I discussed in [Elixir String Processing Optimization](https://blog.jola.dev/elixir-string-processing-optimization), their performance characteristics don’t make them the appropriate choice for all use cases.

The Erlang runtime system offers ETS precisely to solve those problems (though technically that may not be why they were originally created). It offers extremely performant mutable updates and concurrent reads. Just to give you a ballpark notion, a microbenchmark I made showed ETS as about 25 times faster than [Redis/Redix](https://github.com/whatyouhide/redix), with both reads and writes coming in at a median of 2µs. But don’t trust me, if speed matters to you make sure to measure it yourself!

Reading from a table still copies data into your process, so you don’t necessarily have to worry about that mutation, it’s completely limited to the ETS table itself. Another interesting thing about the tables is that writes are destructive, which is interesting because old versions of rows are not kept around until garbage collected, in fact, ETS tables are not garbage collected at all! If the table is dropped or the process that owns it dies (we’ll get into the significance of this in a moment) the memory is freed.

Tables are organized by rows of a single key and one to many values. ETS offers a few different modes: sets, ordered sets and bags. A set is a simple key-value data structure, which means you can probably guess what the ordered set is. Finally, bags are similar to sets, but allow multiple rows to have the same key, as long as the combination of values is unique per row. I’ll focus on sets in my examples.

I briefly mentioned before that an ETS table is cleaned up if the process that owns it dies. When you create a table the process that executes that function automatically becomes the owner and the table’s lifetime is linked to that process. This means you’ll need to think carefully about the processes that create your tables and what code you run on them. The Erlang/Elixir motto of “let it crash” might not apply here! My final example will show a way to get around this.

Finally, it’s worth noting that there’s a bunch of options you can set when creating an ETS table. I’ll describe a few here, but take a look at the [documentation](http://erlang.org/doc/man/ets.html) for all the options. They make a huge difference depending on how you’re planning on accessing and mutating your data, but note that no option is a silver bullet. Your code will not be faster just because you set all possible options.

## The most common use case

Let’s take a look at the lightest option, and also the most realistic one. I call it light because the only code that ever runs in the process itself is the creation of the table. Since we want to allow other processes read and write access to the table, we need to set access level to :public. I’ve also set both :read_concurrency and :write_concurrency to true, meaning that the table is optimized for both concurrent reads and writes. Note that if you need to do a lot of concurrent reads and only a few writes, you’re better off not adding the :write_concurrency, and vice versa.

```elixir
defmodule ThinWrapper do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(arg) do
    :ets.new(:thin, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    {:ok, arg}
  end

  def get(key) do
    case :ets.lookup(:thin, key) do
      [] ->
        nil

      [{_key, value}] ->
        value
    end
  end

  def put(key, value), do: :ets.insert(:thin, {key, value})
end
```

This exposes two simple functions modeled on the `Map` module, but you are free to modify or add more depending on your needs. Using it looks something like this.

```elixir
iex(1)> ThinWrapper.get("key")
nil
iex(2)> ThinWrapper.put("key", "value")
true
iex(3)> ThinWrapper.get("key")
"value"
```

It may look like you’re calling the table operations through the `GenServer` process, but they’re actually running in the calling process. This is hugely performant and means you have a chance to spread the CPU cycles over multiple cores (via the schedulers).

Similarly, you can also create your table in a Supervisor or even in the `start` callback of your application. Depends on your needs and preferences, but you can’t really go wrong with using a GenServer here.

## Secret public table

Here’s another take on a public table, where the table is public but not named and shared through passing the reference to it. The reference can be stored in an ETS table, an Agent, in `:persistent_term`, or just in a simple `GenServer`. It’s up to you and your use case! I’ll show you an example of keeping it in a GenServer and handing out the reference.

This means getting the reference will be slowed down by the `GenServer`. As a single process, it risks being a bottleneck if you frequently need to look up the table reference. In that case, the previous example probably makes more sense for you! Where the secret public table really shines though is when you’re doing a bunch of operations in a row. You pay an initial cost when getting the reference, but calling ETS operations using a reference is noticeably faster than using a global name!

```elixir
defmodule Secret do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(arg) do
    table = :ets.new(:secret, [
      :set,
      :public,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    {:ok, table}
  end

  def handle_call(:reference, _from, table), do: {:reply, table, table}

  def reference(), do: GenServer.call(__MODULE__, :reference)

  def get(table, key) do
    case :ets.lookup(table, key) do
      [] ->
        nil

      [{_key, value}] ->
        value
    end
  end

  def put(table, key, value), do: :ets.insert(table, {key, value})
end
```

Using it involves first getting the reference and then calling operations. Like the previous example I implement some functions for interacting with the table, to hide the sometimes awkward API.

```elixir
iex(1)> table = Secret.reference()
#Reference<0.1557747985.1539178499.257941>
iex(2)> Secret.put(table, "hello", "world")
true
iex(3)> Secret.get(table, "hello")
"world"
```

## Controlled order of operations

Now going in a different direction, a version that runs all operations through the GenServer. This means the process becomes a bottle-neck, operations will be much slower than a concurrent read public ETS table. But in return, we get to control the order of operations. It’s now possible to do things like get a value from the table, calculate a new value based on that and insert that value. In a concurrent public table you risk [write conflicts](https://en.wikipedia.org/wiki/Write%E2%80%93write_conflict) in those cases. If the table is hidden in the GenServer and operations are only exposed through the GenServer, you can build on that to ensure no write conflicts or dirty reads.

So here’s a simplified implementation of this: a toy version of Mnesia! We’ll implement rudimentary “transactions” (it’s not really [transactions](https://en.wikipedia.org/wiki/Database_transaction), there’s no rollback or anything) and, even catch errors to avoid losing the process and the table with it.

```elixir
defmodule Sequential do
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(:sequential, [])
    {:ok, table}
  end

  def handle_call({:sequential, fun}, _from, table) do
    try do
      result = fun.(table)
      {:reply, result, table}
    rescue
      reason -> {:reply, {:error, reason}, table}
    end
  end

  def sequential(fun), do: GenServer.call(__MODULE__, {:sequential, fun})

  def put(table, key) do
    case :ets.lookup(table, key) do
      [] ->
        nil

      [{_key, value}] ->
        value
    end
  end

  def get(table, key, value), do: :ets.insert(table, {key, value})
end
```

Usage:

```elixir
iex(1)> Sequential.sequential(fn tab ->
  Sequential.put(tab, "key", 1)
  v = Sequential.get(tab, "key")
  Sequential.put(tab, "key", v + 1)
  Sequential.get(tab, "key")
end)
2
```

This version lets run arbitrary functions on the ETS table, without risking interleaving our function calls with some other process. If you need real transactions but Redis or some other outside source is too slow, take a look at [mnesia](http://erlang.org/doc/man/mnesia.html) or stop over-engineering and just go for a SQL database. This is probably not a useful pattern for 99% of use cases, but this is still an example of how you can extend and customize a GenServer and ETS table to fit your needs.

## Give away

Finally, we’ve been looking at running more code in the process owning the ETS table, mostly because we want to control the execution order of our operations. This also brings a greater risk of data loss, because the more code we run, the greater the risk of an error. This isn’t always a risk we can afford. In the sequential example, I suggested wrapping the function call in `try/rescue` but that’s not a solution you want to blindly apply to everything. There’s a reason we want to let things crash. And let’s face it, nobody writes perfect code. Sooner or later you get an unexpected error. I [came across](https://steve.vinoski.net/blog/2011/03/23/dont-lose-your-ets-tables/) an interesting solution to this problem, which uses `:ets.give_away`. The [documentation](http://erlang.org/doc/man/ets.html#give_away-3) of this function explains why this is useful to us:

> A table owner can, for example, set heir to itself, give the table away, and then get it back if the receiver terminates.

So we can both keep our cookie and eat it. This enables us to combine two GenServers, one to create the table and pass it on (let’s call this the Manager). The other process then runs whatever operations we would like on the table (let’s call this the Worker). If it for some reason unexpectedly crashes, the Manager regains the table ownership and is free to give it to the Worker again as soon as it has restarted.

First we define the Worker.

```elixir
defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_info({:"ETS-TRANSFER", table, _pid, _data}, _table) do
    {:noreply, table}
  end

  def handle_call({:get, key}, _from, table) do
    case :ets.lookup(table, key) do
      [] ->
        {:reply, nil, table}

      [{_key, value}] ->
        {:reply, value, table}
    end
  end

  def handle_call({:put, key, value}, _from, table) do
    result = :ets.insert(table, {key, value})
    {:reply, result, table}
  end

  def handle_cast(:die, table) do
    {:stop, table, :killed}
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def die() do
    GenServer.cast(__MODULE__, :die)
  end
end
```

Then we define the Manager.

```elixir
defmodule Manager do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    worker = Process.whereis(Worker)
    Process.link(worker)
    table = :ets.new(:give_away, [:private])
    data = {:count, 0}
    :ets.insert(table, data)
    :ets.setopts(table, {:heir, self(), data})
    :ets.give_away(table, worker, data)
    {:ok, table}
  end

  def handle_info({:EXIT, _from, _reason}, table), do:  {:noreply, table}

  def handle_info({:"ETS-TRANSFER", table, _pid, data}, _table) do
    worker = wait_for_worker()
    Process.link(worker)
    :ets.give_away(table, worker, data)
    {:noreply, table}
  end

  def wait_for_worker() do
    case Process.whereis(Worker) do
      nil ->
        Process.sleep(1)
        wait_for_worker()
      pid -> pid
    end
  end
end
```

And this is how we use it (I added it to the application supervision tree)

```elixir
iex(1)> Worker.get("key")
nil
iex(2)> Worker.put("key", "value")
true
iex(3)> Worker.die()
:ok
iex(4)>
23:03:39.308 [error] GenServer Worker terminating
** (stop) #Reference<0.1985539291.2557607937.205065>
Last message: {:"$gen_cast", :die}
State: :killed
iex(4)> Worker.get("key")
"value"
```

This is a very interesting pattern where we combine properties of both resilience and control. We’ve got a thin Manager that avoids running too much code, which makes it more reliable (this may be an oversimplification, but should be true in a very general sense). Work is instead handed off to the Worker which therefore accepts any risks involved while running any business logic. If it crashes, the supervisor restarts it and the Manager re-gifts the ETS table to the new Worker. We both get operation order control and fault tolerance.

There’s a bug in this implementation! If the Worker dies there’s a brief period of time where it won’t accept messages, here’s an example:

```elixir
iex(1)> Worker.die(); Worker.get("key")

13:16:04.010 [error] GenServer Worker terminating
** (stop) #Reference<0.1985539291.2557607937.205065>
Last message: {:"$gen_cast", :die}
State: :killed
** (exit) exited in: GenServer.call(Worker, {:get, "key"}, 5000)
    ** (EXIT) #Reference<0.1985539291.2557607937.205065>
    (elixir) lib/gen_server.ex:989: GenServer.call/3
```

Because the Worker was not alive, the call to `Worker.get/1` failed. I’ll leave working around this as an exercise for the reader, but you can probably get some inspiration from `Manager.wait_for_worker/0`. For a battle-tested implementation of this idea, take a look at [eternal](https://github.com/whitfin/eternal).

## Conclusion

This article showed some very simple general patterns for working with ETS tables in Elixir. Like I mentioned before, none of the examples are intended to be ready for production use, but I hope they can serve as inspiration for your own solutions. Maybe you even picked up a trick or two!

If you’re looking for something more advanced, maybe take a look at Evadne Wu’s [ETS Ecto Adapter](https://github.com/evadne/ets-playground) (work in progress). It should provide a lot of inspiration!
