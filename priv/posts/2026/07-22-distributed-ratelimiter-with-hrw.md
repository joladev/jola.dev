%{
  title: "Distributed rate limiter with HRW in Elixir",
  author: "Johanna Larsson",
  tags: ~w(elixir cluster ratelimiter distributed),
  description: "Building the classic distributed rate limiter, using the HRW library instead of the traditional ExHashRing."
}
---

This is a continuation of [Elixir Cluster 101](https://jola.dev/posts/elixir-cluster-101). So let's talk about putting what we learned into practice using the case of ratelimiting. Many implementations default to running in memory, meaning that it doesn't synchronize across multiple nodes. In most other languages you would immediately reach for something like [Redis](https://redis.io/open-source/) to tackle this. It’s a great tool for sharing state across nodes, especially where your expectations on consistency and fault tolerance are lower, like the case of rate limits.

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
