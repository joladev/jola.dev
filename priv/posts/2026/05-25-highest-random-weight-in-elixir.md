%{
  title: "Highest Random Weight in Elixir",
  author: "Johanna Larsson",
  tags: ~w(elixir hrw oss),
  description: "A description of HRW/rendezvous hashing and the HRW elixir library."
}
---

Consistent hashing is a common building block for distributed Elixir and enables fairly low complexity and high value design patterns, like the distributed rate limiter or cache. I’ve written about it before.

The most common way of assigning keys to nodes, ensuring that any node participating in the cluster can figure out which node owns the given key, is Discord’s ExHashRing. This is an incredibly battle-tested and reliable library with excellent performance characteristics, and I’ve only had good experiences with it.

That said, it does have a downside. You have to start and manage the ring processes. It’s not a huge downside, you can give them global names and it’s trivial to look them up, but you still want them set up under your supervision tree and they are stateful persistent things that hang around. That state has to be managed. It’s not a big deal at all, but when I found a stateless alternative it did immediately catch my attention.

## Rendezvous hashing

As described by the [Wikipedia page](https://en.wikipedia.org/wiki/Rendezvous_hashing): *Rendezvous hashing is both much simpler and more general than consistent hashing.* Also called HRW or Highest Random Weight*.* In practice, you can use it very much like you would ExHashRing.

ExHashRing example.

```elixir
{:ok, ring} = ExHashRing.Ring.start_link()
Ring.add_nodes(ring, ["a", "b", "c"])

Ring.find_node(ring, "key1")
=> "b"
```

HRW example.

```elixir
HRW.owner("key1", ["a", "b", "c"])
=> "b"
```

That’s it. No stateful process, no setup. Just pure functional programming with inputs and outputs. Consistent across multiple machines. Avoids unnecessary drift when changing the list of nodes. You can see why it caught my eye!

There’s a downside of course. The big O notation for `HRW.owner` is linear (O(n)), or in other words, it doesn’t do well with larger lists of nodes. That’s definitely something to take into account when considering using it. But to be honest, looking back at the times I’ve used `ExHashRing` I’ve never had more than ~14 nodes to worry about. Here’s a comparison of how each algorithm does on my machine for 14 nodes.

```elixir
Name                                ips        average  deviation         median         99th %
ExHashRing.Ring.find_node        2.67 M        0.37 μs  ±1149.12%        0.33 μs        0.50 μs
HRW.owner                        0.40 M        2.51 μs   ±207.32%        2.38 μs        3.42 μs

Comparison:
ExHashRing.Ring.find_node        2.67 M
HRW.owner                        0.40 M - 6.70x slower +2.13 μs
```

`ExHashRing` is extremely fast, and stays fast as the number of nodes grow. But at a smaller number of nodes, unless this is an extremely hot path, there’s really not much difference between 0.37 µs and 2.51 µs. You’re free to pick whichever one you think reads better.

## Basic HRW algorithm

Let’s dig a bit deeper into rendezvous hashing. The basic implementation is actually incredibly small. What you want to do is apply a scoring function on the key together with each of the nodes separately and then return the highest value. Highest Random Weight. For a scoring function you can use any fast hashing function really. `:erlang.phash2` is an obvious candidate in the BEAM ecosystem.

Here’s what that looks like.

```elixir
defmodule HRW do
  def owner(key, nodes) do
    Enum.max_by(nodes, fn node ->
      :erlang.phash2({key, node})
    end)
  end
end
```

It’s pretty ingenious!

## Linear growth

Just to demonstrate how that affects performance as `nodes` grows, here’s a benchmark run with 10K nodes. 4200x times slower than `ExHashRing`. Although to put things into perspective, it’s still just taking ~2 ms on my machine. Depending on your use case, that might actually be just fine. It’s hard to beat the convenience of a pure function.

```elixir
##### With input D: 10_000 #####
Name                                ips        average  deviation         median         99th %
ExHashRing.Ring.find_node        1.91 M     0.00052 ms  ±1515.88%     0.00046 ms     0.00063 ms
HRW.owner                     0.00046 M        2.20 ms     ±5.29%        2.17 ms        2.62 ms

Comparison:
ExHashRing.Ring.find_node        1.91 M
HRW.owner                     0.00046 M - 4204.94x slower +2.20 ms
```

But let’s see if we can do better.

## HRW skeleton

Our basic HRW implementation, although actually quite fast, doesn’t behave well as the number of nodes grows. This is because it, for every lookup, has to hash the key against every node. That same Wikipedia page [describes](https://en.wikipedia.org/wiki/Rendezvous_hashing#O(log_n)_running_time_via_skeleton-based_hierarchical_rendezvous_hashing) a way around that by arranging the nodes into an efficient data structure and bringing the big O notation of `owner` to O(log n).

At a very (very) high level what we want to do is sort the list of nodes and then chunk them into clusters. Each cluster gets an address and instead of hashing the key against every node, we now just need to calculate the address of the cluster, and then we can hash the key against the nodes inside that cluster to find the correct one. This means significantly less effort, bringing us to a much nicer logarithmic complexity.

Using it looks something like this.

```elixir
skeleton = HRW.build(nodes)
HRW.owner(key, skeleton)
```

Running the same benchmark as above, but with the skeleton created in advance, just like we do for `ExHashRing`, this is what we get.

```elixir
##### With input D: 10_000 #####
Name                                ips        average  deviation         median         99th %
ExHashRing.Ring.find_node        2.17 M     0.00046 ms  ±1791.93%     0.00042 ms     0.00058 ms
HRW.owner (skeleton)             0.71 M     0.00141 ms   ±634.18%     0.00138 ms     0.00183 ms
HRW.owner                     0.00047 M        2.13 ms     ±5.03%        2.10 ms        2.53 ms

Comparison:
ExHashRing.Ring.find_node        2.17 M
HRW.owner (skeleton)             0.71 M - 3.06x slower +0.00095 ms
HRW.owner                     0.00047 M - 4615.43x slower +2.13 ms
```

We’ve gone from 2 ms per lookup to 141 µs, only ~3x slower than `ExHashRing`, with no NIFs and no stateful processes to start up. We do have a struct we have to pass around now, and adding and removing nodes is no longer a stable operation. Adding a node pushes everything that comes after in the sorted list one slot over. I guess nothing in life is free. Still, this is an interesting tradeoff for a lot of use cases.

## Distribution

The other thing you probably want to know about a mechanism for distributing work/keys/load across a set of nodes, is how well it distributes. It wouldn’t be very useful if every key maps to the same node. Here’s a little sample script that demonstrates the distribution.

```elixir
defmodule Distribution do
  def run do
    keys = Enum.map(1..100_000, fn i -> "key-#{i}" end)

    for n <- [10, 100, 1000] do
      nodes = Enum.map(1..n, &"node#{&1}")
      ideal = div(length(keys), n)

      counts =
        keys
        |> Enum.map(&HRW.owner(&1, nodes))
        |> Enum.frequencies()
        |> Map.values()

      min_c = Enum.min(counts)
      max_c = Enum.max(counts)
      avg = Enum.sum(counts) / length(counts)
      stddev = :math.sqrt(Enum.sum(Enum.map(counts, fn c -> (c - avg) ** 2 end)) / length(counts))

      IO.puts("#{n} nodes, #{length(keys)} keys (ideal #{ideal} per node):")
      IO.puts("  min: #{min_c}  max: #{max_c}  stddev: #{Float.round(stddev, 1)}  (#{Float.round(stddev/avg*100, 2)}% of mean)")
    end
  end
end

Distribution.run()
```

I extended that to add HRW with MurmurHash3, HRW with skeleton, and ExHashRing, for comparison.

```elixir
⏺ 10 nodes, 100000 keys (ideal 10000 per node):
    phash2 (HRW)           min: 9691  max: 10639  stddev: 249.9  (2.5% of mean)
    murmur3 x86_32 (HRW)   min: 9859  max: 10192  stddev: 112.2  (1.12% of mean)
    murmur3 x64_128 (HRW)  min: 9864  max: 10170  stddev: 98.1   (0.98% of mean)
    HRW.Skeleton           min: 9691  max: 10639  stddev: 249.9  (2.5% of mean)
    ExHashRing             min: 9526  max: 10513  stddev: 338.5  (3.38% of mean)

  100 nodes, 100000 keys (ideal 1000 per node):
    phash2 (HRW)           min: 920   max: 1075   stddev: 29.7   (2.97% of mean)
    murmur3 x86_32 (HRW)   min: 934   max: 1059   stddev: 27.0   (2.7% of mean)
    murmur3 x64_128 (HRW)  min: 902   max: 1072   stddev: 29.2   (2.92% of mean)
    HRW.Skeleton           min: 877   max: 1124   stddev: 46.6   (4.66% of mean)
    ExHashRing             min: 105   max: 1229   stddev: 279.7  (27.97% of mean)

  1000 nodes, 100000 keys (ideal 100 per node):
    phash2 (HRW)           min: 69    max: 132    stddev: 9.9    (9.91% of mean)
    murmur3 x86_32 (HRW)   min: 72    max: 132    stddev: 9.6    (9.65% of mean)
    murmur3 x64_128 (HRW)  min: 67    max: 144    stddev: 9.8    (9.79% of mean)
    HRW.Skeleton           min: 72    max: 141    stddev: 9.9    (9.85% of mean)
    ExHashRing             min: 0     max: 147    stddev: 31.4   (31.42% of mean)
```

As you can see, we’re doing just fine with `:erlang.phash2.` Murmur3 is maybe slightly better at smaller node counts, but that’s not the big takeaway from here. It’s that `ExHashRing` is really struggling at larger node counts on the default settings. The solution is to add more vnodes, but that was unexpected to me!

## Announcing HRW, the library

You’re very welcome to try out the `hrw` library on [hex.pm](http://hex.pm), or why not take a look at the Github repository at https://github.com/joladev/hrw. For very large number of nodes, you’ll want to use `ExHashRing` or `HRW.Skeleton`, for anything else, why not stick with plain `HRW.owner`?

The library comes with additional strategies not described here, like `HRW.Weighted` which lets you assign more key space to specific nodes, useful for heterogenous clusters where some machines are bigger, and affinity, which lets you associate keys with certain properties and prefer or even limit them to specific nodes.

Let me know how you find it.
