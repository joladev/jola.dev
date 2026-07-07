%{
  title: "Let libraries be libraries",
  author: "Johanna Larsson",
  tags: ~w(elixir oss),
  description: "A gentle rant on the topic of libraries that run as Elixir applications and why that's an anti-pattern for library design."
}
---

My Elixir library pet peeve: `application.ex`. There are very few reasons for why you would ever need to have a library be its own application, and making it one often encourages anti-pattern library design that leads to less usable code. And yet, I still see a lot of Elixir libraries do this. 

## What does `application.ex` do

This is the file that includes the `start` callback for your application. For most of us, this is how we’re used to working with Elixir. We create our application with `mix phx.new` or `mix new --sup` and that’s what pops out. You get a nice little supervision tree and use it to add your `GenServer`s and whatnot, maybe you put in a logger handler in the startup logic, some logs, maybe set up some telemetry. It’s a very intuitive place to put start up logic.

In fact, tons of your dependencies do this. Try it out for yourself. Here’s what I get when I list the running applications that have their own start callback, for this blog, locally.

```elixir
iex(1)> :application.info()[:running] |> Enum.filter(fn {_app, master} -> is_pid(master) end) |> Enum.map(&elem(&1, 0))
[:jola_dev, :mimic, :image, :req, :sentry, :gettext, :telemetry_poller,
 :nimble_pool, :tailwind, :esbuild, :phoenix_live_dashboard, :phoenix_live_view,
 :phoenix_live_reload, :phoenix, :bandit, :phoenix_pubsub, :plug, :telemetry,
 :plug_crypto, :runtime_tools, :logger, :hex, :inets, :ssl, :mix, :iex, :elixir,
 :sasl, :kernel]
```

While running locally `mix` actually figures out which dependencies are applications and need to be started for you automatically. The way `mix` knows whether to treat something like an application is this bit in the `mix.exs` of the app:

```elixir
  def application do
    [
      mod: {JolaDev.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end
```

Ok! Now we've established the difference between what I'm calling a “library” and an “application”, in the Elixir terminology (even though we tend to refer to both things as libraries when we depend on them). In the OTP world, applications that don't have a `start` callback are known as "library applications". I guess we're not doing ourselves any favors with the terminology.

## Anti-pattern library design

The Elixir docs have an incredible section on [Anti-patterns](https://elixir.hexdocs.pm/what-anti-patterns.html) that I highly recommend reading. They cover all kinds of anti-patterns, whether they’re related to code, design, processes, or meta-programming. Even if you get nothing else out of this article, I’m happy to just be raising awareness of this great resource.

The section I’m focused on here is actually a little bit hidden away under [Using application configuration for libraries](https://elixir.hexdocs.pm/design-anti-patterns.html#using-application-configuration-for-libraries). This section starts out covering the topic of using application config, like what you have in `config.exs`, to let users configure your library. The point it’s making is that if you make your library configurable through app config, since app config is global, each option can only have a single value set per runtime. You can’t have one function use one version and another function use another. This becomes especially bad when we’re talking about transitive dependencies. You want to use one config value for the library, but your dependency that also uses that library wants a different one. Fair enough.

But hidden below, in a sub-header, is the part that I want to rant about: “**Additional remarks: Supervision trees”.** It lays out the case cleanly, by treating it as a different aspect of the same problem that we just talked through. When a library defines an `application.ex` with its own supervision tree, then it’s no longer possible to configure that supervision tree. I can’t put it under a sub-tree of my app, I can’t control the supervision strategy. Not to mention that you can no longer run two instances of that tree, and you can’t conditionally start the library. That last one has bitten me a bunch of times.

I’m not going to list out any libraries that have fallen into the trap of running as an application, and become less configurable and more awkward to use because of it, but I’m sure you’ve run into it yourself. There’s no point in criticizing anyone for their work, especially when we’re talking about volunteered open source libraries. I’m only sharing this to help future library designers avoid this common design anti-pattern.

## Examples of the better design

The docs mention [Nx](https://github.com/elixir-nx/nx) and [DNS Cluster](https://github.com/phoenixframework/dns_cluster) as examples of libraries that offer supervision trees, but let you configure and control them instead of starting them for you in the background. Another great example is [Finch](https://github.com/sneako/finch), the library that underpins the very popular HTTP client [Req](https://github.com/wojtekmach/req). Finch does come with a supervision tree, but in a configurable way where you can define the Finch supervision tree and how it should run. Here’s an example of what adding Finch to your app looks like:

```elixir
children = [
  {Finch, name: MyFinch}
]
```

You can add multiple Finch “instances”, each one with its own set of configuration options.

```elixir
children = [
  {Finch, name: MyFinch},
  {Finch, name: SecondFinch},
  {Finch, 
   name: DifferentOptionsFinch,
   pools: %{
     :default => [size: 10, count: 2],
     "https://hex.pm" => [size: 32, count: 8]
   }
  }
]
```

Each one starts its own supervision tree and runs completely independent of the others. That gives you, the user, an incredible level of configurability.

## An appeal to the community

I’m not saying a library can’t ever be an application, in fact one of my favorite libraries of all time, [Req](https://github.com/wojtekmach/req), runs as an application. It does that to be easier to use and quicker to set up, it starts up a `Finch` instance for you automatically, but [it also supports](https://req.hexdocs.pm/Req.Steps.html#run_finch/1) running separate `Finch` trees, giving you the best of both worlds. It runs as an application without falling into the usual traps. There are reasons your library might need to start something, but it should be the exception and you can almost always solve it some other way.

So when you’re tinkering on your next library, please consider using Finch and the other examples as references and offering it as a fully configurable drop in supervision tree that the user can add to their own tree, with their own options, under their own supervisor. Let your library be a _library_.
