%{
  title: "Speeding up a Phoenix LiveView web app with a CDN",
  author: "Johanna Larsson",
  tags: ~w(phoenix liveview elixir cdn bunny.net),
  description: "Serve your assets on a CDN sub-domain to speed up a Phoenix LiveView web app. All the payoff, none of the effort."
}
---

I’ve written before about using [bunny.net](https://bunny.net/?ref=f0l8865b7g) as a [CDN for this blog](https://jola.dev/posts/dropping-cloudflare), where I basically just cache everything, because it’s a static blog. Whenever I release a new blog post, I purge the pull zone, and the new blog post becomes available. This works great for my blog, it doesn’t have user sessions, no server side dynamic content, also crucially it doesn’t use LiveView websockets. It basically means serving my blog requires no resources on my side at all, it’s fully CDN driven.

For your average Phoenix LiveView web app this won’t work so well though. You’re very likely to have dynamic content, user sessions, and websockets. After some experimentation I found a really high impact low effort approach to using [bunny.net](https://bunny.net/?ref=f0l8865b7g) for this use case, so here’s a little write up.

## A CDN that doesn’t get in your way

Looking over your average Phoenix LiveView web app, the stuff you want to cache is likely being managed by the Plug.Static and Phoenix `assets` pipeline already. `mix assets.deploy` already builds your CSS and JS, as well as managing images, attaching unique hashes on each build. Since every new version produces a new hash, it means we can basically cache assets forever. The way this is hooked up, by default, is you’ve got `static_paths` defined in your Web module, like:

```elixir
def static_paths, do: ~w(assets fonts images robots.txt)
```

and then you’ve got `Plug.Static` in your `endpoint.ex`.

```elixir
  plug Plug.Static,
    at: "/",
    from: :your_app,
    gzip: not code_reloading?,
    only: YourAppWeb.static_paths(),
    raise_on_missing_only: code_reloading?
```

That’s neat thing number one. Number two is that you can configure the URL that static assets are served from. This makes it easy to serve the static assets through a different domain than the main one. Let’s see how we can make excellent use of that! In `runtime.exs` you have a block of config in the prod section like:

```elixir
  config :your_app, YourAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
```

We’re going to add a single line here, `static_url`.

```elixir
  config :your_app, YourAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    static_url: [host: "cdn.yourapp.com", scheme: "https", port: 443],
    ...
```

With that configuration set, we now have to also ensure that all assets are getting full URLs, rather than relative paths, so go through your `root.html.heex` and any other files that include asset URLs, and wrap them in `url`. You want your `app.js` and `app.css` references to look something like this.

```html
<link phx-track-static rel="stylesheet" href={url(~p"/assets/css/app.css")} />
<script phx-track-static type="module" src={url(~p"/assets/js/app.js")}>
```

This means all of your static assets, like `app.js` and `app.css` will be served from `cdn.yourapp.com` instead of from your main host. These assets links get automatically rewritten, no extra work required, assuming they’re wrapped in `url`. So `~p"/images/logo.svg"`  does not get rewritten, but `url(~p"/images/logo.svg")` does.

Okay, that’s the Phoenix side work done. Let’s move on to bunny.net.

## Setting up your pull zone

[Log in to your account](https://bunny.net/?ref=f0l8865b7g) and create a new pull zone, this is the CDN configuration that will sit on `cdn.yourapp.com`. Name it something reasonable and under Origin type select Origin URL and input your website. The rest of the settings can be left at default, although feel free to explore. Note that pull zone names have to be globally unique. Once created, click skip instructions. You’ll land on Hostnames. Add your web site subdomain, eg `cdn.yourapp.com`, and follow the instructions to create the DNS record to point at the pull zone.

Once it’s active, deploy your website, and you should see `app.js` and `app.css`, as well as any other assets, being served through your CDN subdomain. This can significantly reduce the outgoing network traffic for your website, as well as speeding up page loads.

The rest of the pull zone settings can be left in their default state, but consider also activating Origin Shield, which will further reduce the traffic to your server, and play around with “Stale Cache” settings, that let the CDN serve stale assets while re-fetching.

## Conclusion

I want to emphasize that you can put bunny.net directly in front of your web app, you don’t need to limit it to static resources, but the goal of this guide is to show you a low effort high reward approach that requires minimal configuration.

Also leaving a little note on websockets here. Bunny.net used to cap websockets, where you had to pay for a higher tier to get more websocket capacity. Not great for Phoenix LiveView! However, they’ve recently switched to a pay per use model, currently charging `$0.235` per million connection minutes. Dirt cheap, but if all you want to do is speed up asset delivery, there’s no reason to run the websocket connections through bunny.net.

Hope this was helpful!
