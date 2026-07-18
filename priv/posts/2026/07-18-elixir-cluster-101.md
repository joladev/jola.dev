%{
  title: "Elixir Cluster 101",
  author: "Johanna Larsson",
  tags: ~w(elixir hrw distributed),
  description: "A practical guide to clustering your nodes and tracking the cluster state for real use cases."
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
iex(first@127.0.0.1)1> Node.list
[]
iex(first@127.0.0.1)2> Node.ping(:"second@127.0.0.1")
:pong
iex(first@127.0.0.1)3> Node.list
[:"second@127.0.0.1"]
iex(first@127.0.0.1)4> Node.self
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

What we have so far is the foundation of a lot of features you can build on top of distributed Elixir, but it wouldn’t be any fun if we stopped here. In the next blog post we'll take a look at a common use case: consistent rate limiting across multiple nodes. Keep an eye out of that!
