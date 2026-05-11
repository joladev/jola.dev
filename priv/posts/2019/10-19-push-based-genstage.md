%{
  title: "Push-based GenStage",
  author: "Johanna Larsson",
  tags: ~w(genstage),
  description: "GenStage is a pull-based system, where consumers pull events from the producers, and most of the documentation describes this"
}
---
`GenStage` is a pull-based system, where consumers pull events from the producers, and most of the documentation describes this. But it can also be used as a push-based one. The idea is straightforward, consumers register their demand with the producer, and if the producer has buffered events it will satisfy it immediately, otherwise, it keeps track of how much demand it has received. When new events are pushed into the producer it passes it on to the consumers while decreasing the demand stored in state. `GenStage` handles the distribution of the events automatically to the waiting consumers.

This blog post is mostly educational, but this pattern can be applied effectively on all kinds of use cases.

Let’s take a look at a stripped-down example. We’ll set up a producer that accepts messages from any other process, like a regular GenServer, and distributes them to the consumers. We’ll avoid worrying about `min_demand` and `max_demand` and limit consumers to ask for a single event at a time. This is perfectly reasonable where the work is slow and processing time irregular, eg if they involve making requests to network resources. `GenStage` comes with a built-in buffer, if a producer produces more messages than the consumers can handle, they’re automatically buffered with a maximum of `10_000` items by default. We’re not going to rely on it though, we’ll be buffering ourselves in the producer. This has some interesting benefits in improvements we can build to the producer, including backpressure. That’s a future post though.

First out, we define a module using `GenStage` with `start_link` and `init`, with the latter returning a tuple of a queue and an initial demand of 0. If you haven’t seen `:queue` before, take a look at the [Erlang documentation](http://erlang.org/doc/man/queue.html). In short, it allows us to create an efficient buffer for situations where the producer gets pushed more events than the consumers can handle.

```elixir
defmodule Producer do
  use GenStage

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:producer, {:queue.new(), 0}}
  end
```

Next, we’ll define the required `handle_demand` callback. This is called whenever consumers register demand. Note that we can ignore the incoming demand, it’s always 1. We attempt to take an item out of the queue and return it. If there are no items in the queue, we instead register the demand with `demand + 1`. For educational purposes, the incoming demand is also printed.

```elixir
  def handle_demand(incoming, {queue, demand}) do
    IO.inspect(incoming, label: "demand")

    with {item, queue} <- :queue.out(queue),
         {:value, event} <- item do
      {:noreply, [event], {queue, demand}}
    else
      _ -> {:noreply, [], {queue, demand + 1}}
    end
  end
```

Next, we’ll need a way of pushing items into the producer. `GenStage` is built on top of `GenServer` and supports those callbacks, including `handle_cast`. We need to handle two different cases: consumers are waiting for events, and the consumers are busy. The first clause stores the incoming event. In the second clause, we know that there is stored demand and that we’ve received a single item, so we put that in the queue, get the oldest item from the queue and return it while decreasing stored demand by 1.

```elixir
  def handle_cast({:enqueue, event}, {queue, 0}) do
    queue = :queue.in(event, queue)

    {:noreply, [], {queue, 0}}
  end

  def handle_cast({:enqueue, event}, {queue, demand}) do
    queue = :queue.in(event, queue)
    {{:value, event}, queue} = :queue.out(queue)
    {:noreply, [event], {queue, demand - 1}}
  end
```

Finally we expose a public API for ease of use.

```elixir
  def enqueue(event) do
    GenServer.cast(__MODULE__, {:enqueue, event})
  end
end
```

First part is done! Next up is the consumer. It takes an ID in initialization because we want to start a few and keep track of which one did what. `max_demand` is set to 1 to ensure that the consumer asks for one item at a time. In the `handle_events` callback we pretend to work for 500+0..1000 ms, this helps illustrate the way work is distributed on the consumers. They print their own ID, as well as the event.

```elixir
defmodule Consumer do
  use GenStage

  def start_link(id) do
    GenStage.start_link(__MODULE__, id)
  end

  def init(id) do
    {:consumer, id, subscribe_to: [{Producer, max_demand: 1}]}
  end

  def handle_events([event], _from, id) do
    IO.puts("#{id}: received #{event}")
    Process.sleep(500 + :rand.uniform(1000))
    IO.puts("#{id}: finished #{event}")

    {:noreply, [], id}
  end
end
```

You can either start them up manually in IEx or add them to your application supervision tree. If you’re starting them in IEx, it looks like this:

```elixir
iex(1)> Producer.start_link(:ok)
{:ok, #PID<0.189.0>}
iex(2)> Consumer.start_link(1)
{:ok, #PID<0.191.0>}
demand: 1
iex(3)> Consumer.start_link(2)
demand: 1
{:ok, #PID<0.193.0>}
iex(4)> Consumer.start_link(3)
demand: 1
{:ok, #PID<0.195.0>}
```

You can see the consumers immediately subscribing to the producer and registering their demand. Now you’re free to play around with it!

```elixir
iex(5)> Producer.enqueue("hello")
:ok
1: received "hello"
1: finished "hello"
demand: 1

iex(7)> for i <- 1..5, do: Producer.enqueue("message #{i}")
3: received "message 1"
1: received "message 2"
2: received "message 3"
[:ok, :ok, :ok, :ok, :ok]
3: finished "message 1"
demand: 1
3: received "message 4"
2: finished "message 3"
demand: 1
2: received "message 5"
3: finished "message 4"
demand: 1
1: finished "message 2"
demand: 1
2: finished "message 5"
demand: 1
```

## Moving forward

Now that you have this working, here are a few different things you can try extending it with:

1. Update enqueue/1 to take lists of events instead of single items, and update the producer and consumer to handle demand properly, including setting min_demand and max_demand.
2. Keep track of the queue buffer in the producer and shed events if it grows beyond a given size.
3. Add a ProducerConsumer middle step.

## Conclusion

I hope this has been educational or useful! GenStage is a super interesting piece of software, but the concepts involve take a while to wrap your head around, and I wanted to help build on the available knowledge.
