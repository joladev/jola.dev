%{
  title: "The new `Registry.select/2` and what match specs are",
  author: "Johanna Larsson",
  tags: ~w(phoenix plug elixir),
  description: "I want to share a simple pattern for setting up HTTP based health checks for Plug/Phoenix applications"
}
---
The Elixir 1.9 changelog includes a new function for registries, reasonably overshadowed by the new release task and better config handling. I want to tell you a bit about `Registry.select/2`, what it does, and why it’s exciting. This will also include a very brief introduction to how Erlang match specs work.

## Backstory and my experience contributing to Elixir

A while ago I was working on a project where I needed to dynamically start and stop workers polling some third-party service. This was a straightforward setup of GenServer workers, a DynamicSupervisor to keep them, a Registry to look up existing workers, and finally, a coordinating GenServer that starts and stops workers (let’s call it Coordinator). The canonical truth of what workers should be active was in a Postgres database, so periodically the Coordinator would get the latest list of active services. It would then diff that with the last list it saw, to get the names of the workers that should start and stop. It would then be able to look the workers up in the Registry and stop them.

Sounds good enough, right? But something bothered me. When I get the new state from the database I don’t actually diff it against running workers, I diff it against the last state I saw from the database. What happens if the last state diverges from the actual workers running? One practical example of how this could happen is if some worker starts crashing. It would be restarted by the DynamicSupervisor, but given enough crashes within the configured interval, the DynamicSupervisor itself would crash, bringing down all workers. This would not be reflected in the last state in the Coordinator, so it would be completely unaware that the workers it expects to be running are not.

So who knows what workers are running? The [Registry](https://hexdocs.pm/elixir/master/Registry.html) does! Unfortunately, Registry does not expose a way of getting all registered processes.

After bringing this up in the Slack I was encouraged to suggest it on the Elixir mailing list, [which I did](https://groups.google.com/forum/#!topic/elixir-lang-core/FyRAyqJZIPs). Following some discussion with a lot of interesting input from various people I got the go-ahead to make a [PR](https://github.com/elixir-lang/elixir/pull/8963) and after a few iterations, it ended up being merged for 1.9. It was a very positive experience for me, everyone involved was super constructive and helpful and I enjoyed it a lot!

## Registry.select/2

So, the final version that got merged ended up being based on match specs, giving a close to direct access to the underlying ETS table of the Registry. I’ll grab some examples from the documentation to give an idea of what this means.

Get all registered processes, keys and values.

```elixir
iex> Registry.start_link(keys: :unique, name: Registry.SelectAllTest)
iex> {:ok, _} = Registry.register(Registry.SelectAllTest, "hello", :value)
iex> {:ok, _} = Registry.register(Registry.SelectAllTest, "world", :value)
iex> Registry.select(Registry.SelectAllTest, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
[{"world", self(), :value}, {"hello", self(), :value}]
```

Get all PIDs for processes registered with the value :group_a.

```elixir
iex> Registry.start_link(keys: :unique, name: Registry.SelectAllTest)
iex> {:ok, p1} = Registry.register(Registry.SelectAllTest, "hello", :group_a)
iex> {:ok, p2} = Registry.register(Registry.SelectAllTest, "world", :group_a)
iex> {:ok, p3} = Registry.register(Registry.SelectAllTest, "alright", :group_b)
iex> Registry.select(Registry.SelectAllTest, [{{:_, :"$1", :"$2"}, [{:"==", :"$2", :group_a}], [:"$1"]}])
[pid1, pid2]
```

Those examples just showcase a very small part of everything you can do, but hopefully, it’s enough to spark some interest! One thing to note is that if you’re using a very large Registry with many partitions and you grab everything there’s a small performance overhead. To give some context, I made a benchmark early on with a Registry of 8 partitions and a million registered processes. Getting everything took about 400ms. The reason why it’s not blazing fast is that it has to concatenate lists from the 8 partitions. Considering the size of that registry it seems to perform reasonably. And if you filter your results down, not getting all 1 million rows, performance will improve considerably.

## So what are all those weird atoms?

If you haven’t been introduced to match specs before they were created to allow complex queries of data for ETS and [mnesia](http://erlang.org/doc/man/mnesia.html). I’ll take a moment here to just quickly introduce the concept, without digging too deep.

A match spec is structured as a list of three-part tuples, where each tuple consists of a head, optional guards, and the body: `[{head, guards, body}, ...]`. The head is used to select interesting parts of the table, the guards are filters, and finally, the body defines the output format. You can mix values and variables (in the form of `:"$n"`) in all parts, and even function calls in guards and body. For a complete grammar of the match spec, check out the documentation. On top of this, there are some special atoms, like `:_`, `:"$_"`, `:"$$"`.

Combined, the parts of the match spec allow you to define just about any query into your data. That’s what this new function uses to expose the data stored in the Registry. Note that match specs are massaged slightly on the way in from `Registry.select`, to avoid leaking the internal data format. Take a look at the implementation if you’re curious, it’s [only about 20 lines](https://github.com/elixir-lang/elixir/blob/master/lib/elixir/lib/registry.ex#L1196).
Why does it matter?
#

This opens up a bunch of new or simplified use cases for Registry. I mentioned the one that prompted me to start digging into this in the first place, but there are lots of others. On the mailing list, [Michał Muskała](https://michal.muskala.eu/) suggested it would simplify another interesting use case, where you would otherwise keep multiple registries. One to keep all existing processes, and then one for each group of processes to maintain some form of membership. After the introduction of `Registry.select/2`, you would instead be able to query a single registry for group membership, for example by keeping it in the `value` part. In fact, a version of that is the second example I showed before. I’m sure you can think of other elegant use cases!

[Horde, the distributed supervisor](https://github.com/derekkraan/horde), apparently used to have similar functionality, but it was dropped to keep a consistent API with Registry. Now that it’s being added to Elixir, [it’s coming back](https://github.com/derekkraan/horde/pull/110).

## Last few words

I just want to thank Jose Valim and the core team, and everyone else involved! This was such a positive experience for me and I’m amazed that I was able to, with their guidance, contribute to the language that I’ve fallen in love with. Thank you, and thank you the Elixir community for being so friendly and welcoming!
