%{
  title: "Cluster singleton pattern",
  author: "Johanna Larsson",
  tags: ~w(elixir distributed cluster pattern),
  description: "You can register a process name globally in Elixir and OTP will ensure it's unique, but there are some surprising edge cases. This shows a pattern for safely defining cluster singletons."
}
---

Continuing the series on distributed Elixir, let’s talk about how to safely run a single instance of a process in a cluster. Well, as safe as we can make it. **There's also an incredible cluster related murder mystery story if you continue reading!**

But first, if you haven’t read [Chris Keathley’s](https://keathley.io/) [The dangers of the Single Global Process](https://keathley.io/blog/sgp.html) you should probably do that before you continue. If you’re into that kind of reading, also take a look at [To spawn, or not to spawn?](https://www.theerlangelist.com/article/spawn_or_not) by Saša Jurić. I’ll just let those articles explain how to think about trying to run a single global process, and the risks that brings.

There are times when a single global process is genuinely the best path forward though, or to be perfectly honest, where it’s the *lesser evil*. As long as you’re aware of the trade offs you’re making, no reason why you can’t make them. Running a single global process in a single node environment is straightforward enough, but things get more interesting in the context of a cluster.

So let’s talk about how to do this safely, because doing this can fail in incredibly confusing and frustrating ways, including some interesting ones that I’ve had the fortunate/misfortune to experience in production!

## Globally unique processes in a cluster

As expected from a platform that ships a built in `ssh` server, OTP comes with the functionality to register globally unique processes built in, and it uses standard mechanisms that you’ll recognize if you’ve been working with GenServers. Where you would pass a `name` to `GenServer.start_link` you wrap that name in `{:global, name}`. This means that instead of locally registering that process, it’s registered globally across the cluster.

Let’s set up a silly example to illustrate all of this: the `GlobalCache`. It’s a single shared cache across the cluster, that cluster members can use to share information.

```elixir
defmodule GlobalCache do
  def get(key) do
    GenServer.call({:global, __MODULE__}, {:get, key})
  end

  def put(key, value) do
    GenServer.cast({:global, __MODULE__}, {:put, key, value})
  end
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key, state)}
  end

  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end
end
```

Now just like you can do `send(Global, message)` to send a message to a process that has been registered under the name `Global` you can equally send a message to the globally registered `Global` with `send({:global, Global}, message)`. What happens under the hood here is that OTP maintains a global process registry, just like it does the local registry, with information about where to find the process. When registered globally, this works across the cluster, and any member of the cluster can now talk to our process! By wrapping `name` in the `:global` tuple our local process has now gone *global*.

Now let’s talk about how to use it in the real world.

## Putting it in production

We’ve talked about the basics of how this works, but there are some practicalities to deal with too. If you have a cluster of three nodes, what happens when they all try to start `Global`. What happens to the ones that lose? Only one node can start it.

The elders of OTP have thought of this, of course, and `GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})` fails with `{:error, {:already_started, pid}}` if someone already owns that name. So one node gets a running process, the other three fail! We have to handle this. Let’s upgrade our example, we need a new version of `start_link`.

```elixir
  def start_link(opts) do
   case GenServer.start_link(__MODULE__, args, name: {:global, __MODULE__}) do 
     {:ok, pid} -> 
       {:ok, pid} 
  
     {:error, {:already_started, pid}} -> 
       Process.link(pid) 
       {:ok, pid} 
   end 
  end
```

This brings in two new concepts. The first is that we try to start but if someone gets there before us, we accept getting benched, but we bide our time. We set up a link on the winner, which is on a different node but that doesn’t stop OTP, and silently continue. And then at some point, if the winner crashes or shuts down for whatever reason, we get the `:DOWN` message and promptly exit, triggering the supervisor to restart us, and we get another shot at the limelight!

This actually works really well, and it’s a really elegant pattern that leans heavily on the design of OTP. Everything just works, links, down messages, cross cluster messaging. It’s beautiful!

Now let’s talk about how this can go *horribly, horribly wrong*.

## Rolling deployments

Now let me tell you a story from many years back, when I was working at an Elixir startup that was doing a lot of very resource intensive work that also had to go really fast. The result was that we had a lot of nodes running, to deal with the load. And, as is and was the fashion, we were running Kubernetes and doing rolling deploys. This means that we didn’t just stop all the nodes and then start new ones, we would start a few new ones, stop a few old ones, rotating through them all until none of the old ones were left around. This is commonly done to minimize disruption to the running system.

At some point, it’s unclear exactly when, we started seeing nodes randomly shut down during this process. In the Kubernetes world a node shutting down isn’t a big deal, it just restarts it. There was no disruption to the running service, so it didn’t get a lot of attention put into it, but we kept seeing the behavior over weeks. Some deploys had no shutdowns, some had multiple. On a rare occasion the unexplained shutdown exploded through all the nodes, but since Kubernetes kept restarting them, in practice it wasn’t much of a problem.

Still, whenever I had spare time I investigated this issue because, let’s face it, it’s a fascinating mystery! The only error message we ever saw was.

```elixir
Kernel pid terminated (application_controller) ({application_terminated,swoosh,shutdown})
```

Now if you were around back then, you might know what it was! An incredible set of very rare conditions happening in concert and resulting in an application dying. Let me take a stab at explaining it.

[Swoosh](https://github.com/swoosh/swoosh) is an email library, included in the new Phoenix project scaffolding, that has an adapter that’s just intended for local dev. It runs an in memory process that holds the emails. To support clusters, it actually used the pattern I showed above to attempting to claim the global name and falling back to monitoring. And, unfortunately, the test adapter ran by default, even in prod.

So what was happening was that the node owning the swoosh process shut down, sending a `:DOWN` message to every single other node alive. Each one has a linked process that exits in response, and then they would all scramble to register the new global name. Sometimes, the winner would be another node that was shutting down as part of the deployment, sending another `:DOWN` message to every other node. When the stars aligned, the nodes winning the right to register the global name kept being part of the nodes shutting down, triggering `:DOWN` message after `:DOWN` message, each one resulting in an abnormal exit returned to the supervisor. 

Which supervisor you ask? Well, the Swoosh application supervisor. And that’s very relevant, because of one of the built in behaviors of OTP. You see, the wise elders recognized that it would be very bad if a process kept crashing and getting restarted forever. So they put a default limit of 3 times in a 5 second interval. If a process crashes more than 3 times in a 5 second interval, the *supervisor crashes*. Which is Swoosh. So Swoosh itself crashes, which takes down the whole node. Because of rolling deploys!

You can read the [original bug report here](https://github.com/swoosh/swoosh/issues/716), which mentions the fix I applied, turning off the local adapter, but that also brought a much cooler solution: adding a separate manager process to handle the starting/restarting.

## Introducing the cluster singleton manager

The basic principle here is that instead of linking to the winning process, we use a manager process per node, that doesn’t need to be globally unique, to track who the winning process is and to attempt to start its own child whenever the winner exits. This means we no longer propagate waves of exits across the cluster. And we can do this in a way that’s actually pretty neat and re-usable. Introducing the `SingletonManager`:

```elixir
defmodule SingletonManager do
  use GenServer

  def start_link(opts) do
    module = Keyword.fetch!(opts, :module)
    GenServer.start_link(__MODULE__, opts, name: manager_name(module))
  end

  @impl GenServer
  def init(opts) do
    module = Keyword.fetch!(opts, :module)
    child_opts = Keyword.get(opts, :opts, [])

    start_or_monitor(module, child_opts)

    {:ok, %{module: module, opts: child_opts}}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    start_or_monitor(state.module, state.opts)

    {:noreply, state}
  end

  defp start_or_monitor(module, opts) do
    pid =
      case module.start(opts) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    Process.monitor(pid)
    pid
  end

  defp manager_name(module), do: Module.concat(__MODULE__, module)
end

```

You can also make this specific and just hard code your module name in here if you want, but this version can be re-used for any other process, and you can use a bunch of them in the same project if needed. The way you use it looks like this in your `application.ex`:

```elixir
  @impl true
  def start(_type, _args) do
    children = [
      {SingletonManager, module: GlobalCache, opts: []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shelf.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

We also have to implement a start function to our `GlobalCache` to support starting it without linking.

```elixir
  def start(opts) do
    GenServer.start(__MODULE__, opts, name: {:global, __MODULE__})
  end
```

## Conclusion

Although it takes a very specific scenario to expose the issue, with Kubernetes and rolling deploys becoming the industry standard, this is a good pattern to keep in your back pocket. And you don’t need to wait for it to become an issue first in your codebase, it’s cheap and clean enough to just use as the standard way of running globally registered processes.

I regret not reporting and writing up the Swoosh issue back when I ran into it. As far as I can remember, my assumption was that I was doing something wrong, or that the scenario was so obscure that a report would not be useful. That was obviously wrong!

But this blog post can at least serve as a record of the failure scenario and the pattern to deal with it, even if I’m writing it many years later!

Let me know if you enjoyed it and if you want me to continue writing about distributed Elixir.
