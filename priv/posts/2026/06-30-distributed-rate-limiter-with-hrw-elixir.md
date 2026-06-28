%{
  title: "Distributed rate limiter with HRW in Elixir",
  author: "Johanna Larsson",
  tags: ~w(elixir hrw distributed),
  description: "A practical guide to tracking cluster state and using it for real applications like a distributed rate limiter."
}
---

One of the main super powers of Elixir (and other BEAM languages) is the built-in functionality for clustering nodes and communicating transparently across the cluster. Any distributed systems normally come with serious disclaimers. It’s very hard to get synchronized state across a cluster right, avoiding corrupted states during net splits or unreliable networks, dealing effectively with rolling deploys and mismatching versions of code.

But that shouldn’t discourage us. There’s a wide range of use cases for distributed Elixir, also known as `disterl` (and a bunch of other things, we really need a consistent name for this). You just need something that matches a few basic criteria:

- It’s okay if some data is lost
- It’s okay if some data is incorrect

As long as those criteria match, distributed Elixir, and distributed systems, are not actually that scary. Because it’s going to work most of the time, and for the use cases that match those criteria it’s frequently going to be a really good, low effort, and very performant option.

## Where do you start

Before anything else, you need to ensure you’re starting your nodes in a cluster enabled configuration. If you’re using Phoenix and releases, this might just be a matter of editing `env.sh.eex` to add something like

```elixir
export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=app@$(hostname -i | awk '{print $1}')
```

and to ensure [DNSCluster](https://github.com/phoenixframework/dns_cluster) is configured.

or if you’re trying this out locally, start a few nodes with

```elixir
# First terminal tab
iex --name first@127.0.0.1
# Second terminal tab
iex --name second@127.0.0.1
```

They’re started in distributed mode, but are still not connected. Let’s do that next. Go to the tab for one of the nodes, let’s say `first`.

```elixir
iex(second@127.0.0.1)1> Node.list
[]
iex(second@127.0.0.1)2> Node.ping(:"second@127.0.0.1")
:pong
iex(second@127.0.0.1)3> Node.list
[:"second@127.0.0.1"]
iex(second@127.0.0.1)4> Node.self
:"first@127.0.0.1"
```

And we’re connected! Although really cool, it’s not really enough to just be connected, we want to be able to do something with it.

## Tracking cluster state

Generally, building on top of the cluster functionality of Elixir starts with tracking the state of the cluster itself. This means keeping track of which nodes are members of the cluster, and when nodes join and leave. The latter is especially important for modern stacks that do rolling deploys, maybe many times a day, meaning constant churn of cluster membership.

The magic invocation that gives us access to the cluster membership transitions is `:net_kernel.monitor_nodes(true)`. Call that function in a `GenServer` and you’ve subscribed to events for nodes joining and leaving. Let’s look at an example of a process that keeps track of the cluster state.

```elixir
defmodule Cluster do
  use GenServer

  require Logger

  def members(name \\ __MODULE__) do
    GenServer.call(name, :members)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    :net_kernel.monitor_nodes(true)
		nodes = [Node.self() | Node.list()]
		Logger.info("Cluster: #{Enum.join(nodes, ", ")}")
    {:ok, nodes}
  end

  @impl GenServer
  def handle_info({:nodeup, node}, nodes) do
    Logger.info("Cluster: #{node} connected")
    {:noreply, [node | nodes]}
  end

  def handle_info({:nodedown, node}, nodes) do
    Logger.info("Cluster: #{node} disconnected")
    {:noreply, List.delete(nodes, node)}
  end

  @impl GenServer
  def handle_call(:members, _from, nodes) do
    {:reply, nodes, nodes}
  end
end
```

As nodes join and leave, we’ll see logs outputted. But more importantly, we can now get the current list of nodes in the cluster at any given point using the `Cluster.members()` function call. In a production setup, we’d also want to track the state of the cluster as metrics, maybe a nice `gauge`/`last_value` of connected nodes, or a counter for every change in membership. Unreliable networks can cause churn or [net splits](https://en.wikipedia.org/wiki/Netsplit), where some nodes are connected but lack a connection with the other nodes. It’s important to track the reliability of the network, and alert on things like nodes failing to connect after a given amount of time.

## What next?

What we have so far is the foundation of a lot of features you can build on top of distributed Elixir, but it wouldn’t be any fun if we stopped here. Let’s take a look at a common use case: consistent rate limiting across multiple nodes.

In most other languages you would immediately reach for something like [Redis](https://redis.io/open-source/) to tackle this. It’s a great tool for sharing state across nodes, especially where your expectations on consistency and fault tolerance are lower, like the case of rate limits.

But we have the option of avoiding adding another service to our stack: we can take a rate limiter that runs in local memory and make it (mostly) consistent across a cluster of nodes. We do this by using an algorithm for assigning each key, whether IP, user ID, or organization ID, to a specific node, and then ensure that all rate limit lookups are routed to the correct node.

Traditionally this has been done using [ExHashRing](https://github.com/discord/ex_hash_ring) (the battle-tested [consistent hashing](https://en.wikipedia.org/wiki/Consistent_hashing) implementation for Elixir), but for clusters with less than 10 nodes there’s an alternative that’s potentially even faster and has slightly better distribution: [HRW](https://github.com/joladev/hrw) (highest random weight, also known as [rendezvous hashing](https://en.wikipedia.org/wiki/Rendezvous_hashing)). They both do the same thing, use ~~magic~~ math to associate any given key with a specific node, given a specific set of nodes. And both HRW and consistent hashing share the same incredibly important property: they cause minimal key re-assignment as the list of nodes changes. This means that if you auto-scale a node here and there, it won’t invalidate every key→node assignment, instead just a minimal subset.

Ok, that’s enough of that. Let’s take a look at the example code. I’m using Hammer here, but you can use any rate limiter.

Setting up the Hammer backend.

```elixir
defmodule HammerBackend do
  use Hammer, backend: :ets
end

```

and then our rate limiter.

```elixir

defmodule RateLimiter do
  use GenServer

  require Logger

  @scale :timer.minutes(60)
  @limit 10

  def hit(ip) do
    nodes = Cluster.members()
    node = HRW.owner(ip, nodes)
    GenServer.call({__MODULE__, node}, {:hit, ip})
  catch
    :exit, reason ->
      Logger.warning("Tried to check rate limit but failed", reason: inspect(reason))

      # We can fall back to a local check here, but you can also skip the check
      # and allow it, and instead ensure the cluster is available most of the time.
      hit_internal(ip)
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    {:ok, []}
  end

  def handle_call({:hit, ip}, _from, state) do
    {:reply, hit_internal(ip), state}
  end

  defp hit_internal(ip) do
    HammerBackend.hit(ip, @scale, @limit)
  end
end
```

That’s it. That will do the job. The magic part is this

```elixir
    nodes = Cluster.members()
    node = HRW.owner(ip, nodes)
    GenServer.call({__MODULE__, node}, {:hit, ip})
```

We grab the latest state of the cluster from our `Cluster` tracking process, and then delegate to `HRW` to figure out what node is currently responsible for the given key (IP), and pass the request on to that node. If it’s the same node, it’s delivered to the local mailbox. If it’s not, it’s routed to the correct node and process, and the rate limit lookup is done there.

Tada! The local only rate limiter is now cluster aware, and will accurately maintain rate limits as long as the cluster is healthy. Redis is great software, but why add it if you don’t need it? Nice.

## A reusable pattern

This pattern works across lots of different use cases. We’ve covered rate limiting, but it also works great for caching. Instead of a `RateLimiter` `GenServer` we would have a `LocalCache` one, but the pattern is the same. Another use case I’ve gotten good use of in the past is where you want to cheaply track events in an ephemeral way, for observability that doesn’t quite fit in Prometheus metrics, traces, or logs.

It’s a powerful pattern and low effort to implement, where it makes sense. Hope this is useful to people!
