%{
  title: "Building Hex Diff",
  author: "Johanna Larsson",
  tags: ~w(hexpm),
  description: "I wanted to give some insight into the Hex Diff project, how it works, and some issues we ran into on the way."
}
---
I wanted to give some insight into the Hex Diff project, how it works, and some issues we ran into on the way. The project is [open-source](https://github.com/hexpm/diff), so feel free to look behind the curtain to see what makes it tick. Some parts of the project originate from my toy version (no longer live), but others were written specifically for this project. We also ended up finding and fixing a bunch of bugs in other projects!

## The Search View

I was excited to finally have a good use case for LiveView, and although it took some time to figure out how to interact with `select` tags, the end result is amazingly snappy. Adding suggestions, based on what you’ve typed, and handling corner cases like packages with only one version was a breeze. The result is a user-friendly UI that searches as you type and when you find the package you’re looking for makes it easy to select a version range. A page like this really makes LiveView shine.

## Reading Data From Hex

If you want to interact with Hex and you’re using a BEAM language, you’re in luck. The Hex team created a library called [hex_core](https://github.com/hexpm/hex_core/) that cover all kinds of interesting functionality.

Hex has an API with loads of useful endpoints, including search, but we ended up not using those at all. The Hex API is rate limited based on your API key, and even though we could have set up a special key for this project, the very fact that the endpoints are rate-limited tell us something. Calling them is not free. If we can avoid them, we should.

Really, the only things we need are a list of package names and a list of versions for each of the packages, and we’ll be able to implement our own search. Luckily, `hex_core` also lets you query the CDN fronted registry itself for simple stuff, like getting all package names and versions! This means we can do super cheap requests for this data.

The last thing to consider is how LiveView works. While typing into the input field every single key input turns into an event on the backend. Although you could build throttling into this, the slower you are to react to the events, the less snappy the UI feels. Instead of loading all the repo data from Hex on `mount` into each LV process, or throttling or debouncing events, I went with a different approach. I set up an ETS table to own all the data, and then a process that periodically refreshes it with the latest results from Hex. Now we can query the package name and version data directly from ETS, and not worry about LiveView overloading anything while making the UI super fast.

## Generating and Rendering Diffs

The first toy version of my web differ just shelled out to `mix hex.package diff` and used a [JS library](https://github.com/rtfpessoa/diff2html) on the frontend to render the diff. This was an easy way to get started, but it limited our ability to make improvements. We needed to move more of the functionality into the project, and into Elixir.

To avoid requiring `mix` on the machine that runs [diff.hex.pm](https://diff.hex.pm/), we recreated the functionality in `mix hex.package diff` command. Again relying on `hex_core`, which also exposes functions for downloading package tarballs and unpacking them. Once we have the two packages unpacked locally, it’s just a question of shelling out to `git diff`. A possible route of improvement, also suggested by [Hauleth on the forum](https://elixirforum.com/t/announcing-hex-diff/28421/10), is to run the git diff algorithm as a NIF, to avoid shelling out at all!

But now we have a text representation of a diff. How to do we get to rendered HTML from here? Luckily I found an [Elixir package](https://github.com/mononym/git_diff) that parses that text representation and turns it into Elixir structs. To verify that the package works correctly, I downloaded the entire Hex registry, created diffs for the first and last version of each, and parsed all of them. I found some diffs that broke the parsing logic, and we were able to fix those bugs.

Once we had the diff represented as Elixir data structures, it was just a question of rendering it as HTML. Because this was already a Phoenix project, `Phoenix.View.render_to_iodata` did the trick. Note that the diff itself is rendered separately from the response sent to users. Every time a new diff is generated it is rendered and stored in the cloud. This means if you request the same package and from/to range, we serve a pre-rendered diff!

The key to effective use of caching is in how you create the cache key. An early version of Diff based the key on the package name, from version, and to version, but that introduces a subtle bug where the Diff service can return incorrect diffs. When a package is pushed to Hex it is immutable and kept forever, except not immediately. The package uploader has a grace period, where they can upload a changed version of the package. This means package maintainers have a chance to fix their mistake if they accidentally uploaded a broken package and noticed in time. It also means that an attacker with access to the credentials to upload a package can create a new version, ask Diff to generate a diff for it (and cache it), and then modify the package on Hex. The diff would be unchanged because the key only relies on name and version range.

To avoid this problem, Diff also incorporates the latest checksum of the two diffed packages in the key. So even if a diff is created in the grace period, it wouldn’t be served after the package modified because the checksum would change. Finally, in order to update the rendering logic for diffs, the key also includes a cache version key. In order to invalidate the diff cache, all you have to do is bump the cache version key in the configuration. Or clear out the storage itself. [Here’s the module for local diff storage](https://github.com/hexpm/diff/blob/master/lib/diff/storage/local.ex).

## GCP Load Balancer

One thing we noticed just as it was put into production was that the GCP load balancer is not very friendly to apps using WebSockets. Unlike many other load balancers, it doesn’t differentiate between active and inactive connections. Both are closed after the timeout, [which is 30s by default](https://cloud.google.com/load-balancing/docs/https/#websocket_proxy_support), and there’s no way to configure it to allow active connections to stay around longer than that timeout. The way Phoenix handles WebSockets is that it keeps the connection alive by repeatedly sending heartbeats, but that doesn’t help here.

For many WebSocket applications that might be fine, you just re-establish the WebSocket connection. But LiveView doesn’t handle it well. When the connection is lost, the LiveView process on the server-side dies. That means that when you reconnect, the state is lost. [Steve Bussey](https://twitter.com/YOOOODAAAA), the author of [Real-Time Phoenix](https://pragprog.com/book/sbsockets/real-time-phoenix), pointed me to this [forum thread](https://elixirforum.com/t/liveview-and-rolling-restarts/23973/9) where [Chris Mccord](https://twitter.com/chris_mccord) mentions a potential solution where you keep the state on the client-side. That way, when you reconnect, you can rehydrate the LiveView process with the state from the client. Hopefully, a future version of LiveView will have this built-in. Just as an experiment I implemented this, but it’s a lot of code to maintain when there’s an easier solution that covers most cases.

According to [GCP’s documentation](https://cloud.google.com/load-balancing/docs/https/#timeouts_and_retries), if you want to use WebSockets or other long-running connections, the solution is just to increase the timeout. That’s what we did, and now it’s fairly unlikely that anyone is interrupted by the WebSocket connection timing out!

## Testing

Testing the search view was an interesting problem. There’s a lot of logic there, plus the search itself ultimately relies on Hex. I decided to use [Mox](https://github.com/dashbitco/mox) to be able to control the results of `get_packages` and `get_versions` in the search view. Once I had that set up, using the [LiveView testing helpers](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html) made the rest a walk in the park. Being able to do this without having to set up automated browser testing was a great relief! You can see what that looks like [here](https://github.com/hexpm/diff/blob/master/test/diff_web/live/search_view_test.exs).

## Conclusion

A huge thank you to everyone involved! The Hex team has been so great. [Eric Meadows-Jönsson](https://twitter.com/emjii), [Wojtek Mach](https://twitter.com/wojtekmach), and [Todd Resudek](https://twitter.com/sprsmpl) have all been there every step of the way, discussing ideas and solutions, and providing support and expertise. And a big thank you to everyone else who answered the hundreds of questions I’ve been asking throughout this project. You’re all part of making this community amazing!
