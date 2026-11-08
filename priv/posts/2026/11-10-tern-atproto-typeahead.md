%{
  title: "Incredibly fast atproto account typeahead search",
  author: "Johanna Larsson",
  tags: ~w(atproto tern rust tantivy fjall),
  description: "Tern is a single binary atproto account typeahead, covering both display names and handles"
}
---

tldr; tern is a single binary [atproto account typeahead search service](https://typeahead.cove.town) that reflects handle changes within a few seconds and is a drop in replacement for the Bluesky service.

There are lots of places in modern apps where you want to be able to discover and fill in user account names, like selecting a username in a login page, or when mentioning a user in a document. You can type my handle into the login page for pckt.blog and it shows up, or in a Bluesky post, and a bunch of other places in the atproto ecosystem. It's such a common pattern for interacting with software that it might not really stand out as anything special at all, until you think about the fact that pckt.blog and Bluesky are not the same company and don't run on the same software. Not only that, but my account doesn't even live on either app's services, it lives on my own self-hosted Tranquil PDS instance. So how do you search all the atproto accounts in the world?

The first, and still the most common, way is Bluesky's actor search. It's a public XRPC query called `app.bsky.actor.searchActorsTypeahead` and is accessible through the Bluesky public API domain, behind a CDN, which basically means you're free to use it as much as you want (within reason). It's a great thing to exist for the community and is a quick and easy building block for making your own atproto app. Try it out yourself!

```bash
curl https://public.api.bsky.app/xrpc/app.bsky.actor.searchActorsTypeahead?q=jola.dev&limit=1 | jq
```

you should get something like

```json
{
  "actors": [
    {
      "did": "did:plc:bvraa6gajy4tfr3eh2sisdkr",
      "handle": "jola.dev",
      "displayName": "johanna",
      "avatar": "https://cdn.bsky.app/img/avatar/plain/did:plc:bvraa6gajy4tfr3eh2sisdkr/bafkreih345bhwbpq7hbmfok2fyw37lkf6us6dsldvdddbb2vaazirpcod4"
    }
  ]
}
```

Changing the `q=` part obviously lets you search for other accounts. And it's fast too, it responds in 100-200ms on my home wifi. It gives you everything you need to power a good typeahead experience, little avatar images and display names.

But it has some shortcomings. It actually works best inside the Bluesky app, where it uses contextual information, like who you follow, to give you better results. It only indexes accounts that have a Bluesky profile. I can't confidently describe how it does ranking on the public authenticated endpoint, since it's no longer open source. It used to look at followers and follows to score each account. It no longer being open source definitely counts as a short-coming for a service that third parties rely on. And of course, it relies on the Bluesky AppView list of accounts, which isn't necessarily the same as "all accounts".

## Alternatives

The largest and most commonly used alternative in the ecosystem is [typeahead.waow.tech](https://typeahead.waow.tech), built and maintained by [@zzstoatzz.io](https://bsky.app/profile/zzstoatzz.io), who also runs a relay and other services. It comes with a landing page where you can try it out, and some usage statistics. It's also open source, so we can look under the hood and actually see what the scoring algorithm is. A quick look says it's followers and follows and account age, as you'd expect as a user coming from Bluesky's service. I have been using it for [shelf.cafe](https://shelf.cafe) and [annot.at](https://annot.at) and it's been great. As much as I appreciate the investment Bluesky has made into the community, and how the company has driven the development of the AT Protocol, I think it's a great sign of health that there are alternative services available.

Going through the public codebase, it's pretty complex! It has a lot of components that are interacting, some of it running on Cloudflare Workers, some of it is a Zig service that deals with ingesting data from the firehose and other places, the service that holds the actual search index is written in Rust and uses [tantivy](https://github.com/quickwit-oss/tantivy), an embedded search engine. It's also heavily documented, which is nice!

Another example of atproto account typeahead, that takes a different approach, is Tangled's `org.tangled.actor.searchActorsTypeahead` XRPC endpoint. Here's a sample query:

```bash
curl 'https://api.tangled.org/xrpc/org.tangled.actor.searchActorsTypeahead?q=jola&limit=1' | jq
```

and I get

```json
{
  "actors": [
    {
      "uri": "at://did:plc:bvraa6gajy4tfr3eh2sisdkr/org.tangled.actor.profile/self",
      "did": "did:plc:bvraa6gajy4tfr3eh2sisdkr",
      "handle": "jola.dev"
    }
  ]
}
```

The most notable difference is that it doesn't contain the Bluesky profile display name nor the avatar, instead it points back at the Tangled profile record. Or in other words, it's not designed to be a replacement for the Bluesky service, rather it's specifically meant to be used for Tangled. Fortunately Tangled is also open source so we can look at the underlying implementation. Apart from the differences in the format returned, it also has pretty significant differences in how it builds its index. The biggest one maybe is that it only tracks accounts that have interacted with Tangled. Or in other words, if you haven't logged into Tangled, you don't show up in the search. Which seems reasonable, it's unlikely that people are mentioning accounts not on the platform. It also avoids the complexities of measuring the "importance" of accounts and instead opts for prefix matched handle search.

Interestingly it creates this index on demand on start up, and does not persist it across restarts. This works because it's much smaller than one that tracks all accounts on the protocol, and is a very neat design. If you wanna learn more about the Tangled API server here's [the launch post](https://tangled.org/blog/bobbin/) and the [codebase](https://tangled.org/tangled.org/core/tree/master/bobbin). Oh, and should I say, bobbin also uses tantivy.

## A few weeks ago

[shelf.cafe](https://shelf.cafe) got some attention and I got a flurry of feedback, which was all very exciting. But there was one piece of feedback that surprised me: that the login page account typeahead was too slow. I had not experienced it as slow before, but after getting that feedback I couldn't stop seeing it. I changed it from a debounce to a throttle, and that made it feel a bit more responsive as queries were sent out at the front of writing instead of after a break, but as I kept trying different options I realized a basic fact: for it to feel instant it can't be far away from my server.

_As an aside, I reported this to [@zzstoatzz.io](https://bsky.app/profile/zzstoatzz.io) who made some tweaks and cold queries from my location have now gone down from ~1s to 400ms._

This led me down a rabbit hole of what it actually takes to build a typeahead search. Tantivy comes up wherever you look, so that seemed like an obvious choice. That also means this will be a Rust project. Some research showed that the full set of accounts across the protocol is about 42M at the time of writing. I did some rough estimates on how much disk space sqlite would use to store all of those accounts with some basic account data and something like follower counts for ranking, and came up with about 8GB. The same estimate for Fjall DB came out to <6GB, mostly thanks to the built in LZM compression and more compact data layout.

I have recently spent some time looking at how Slingshot works under the hood, so taking some inspiration from there, I came up with a rough design. I wanted to try to have a single flow of data through the system, with multiple sources like backfill, jetstream, stale accounts, and have every identity all go through the same data pipeline: resolve identity, fill in fresh account data, store in DB, update index. Everything in a single service that will live with my other apps, on the same server.

The biggest question was backfill. I had a version up early on that listened to account events on the jetstream, and for each one resolved the identity using [slingshot.cove.town](https://slingshot.cove.town), but I quickly realized it would take a long time to discover even just the top 50% active accounts. So I did a comparison of the alternatives: [plc.directory](https://plc.directory), [Jetstream V2 backfill](https://bsky.network/docs/jetstream-replay/), and [Hubble](https://atproto.com/blog/introducing-hubble-a-public-mirror-for-the-whole-atmosphere). I had a hunch that Hubble was gonna win out, after having read [@kandake.africa](https://northsky.app/profile/kandake.africa)'s [blog post](https://50-shades.pckt.blog/building-the-social-graph-with-hubble-and-jetstream-z8afdj6). Feel free to do your own math, but for my use case where all I care about is collecting identities, basically dids, serially paginating through the PLC would take about 3.4h (with no reate limits), pulling down the Jetstream v2 backfill would take 34-68h, and Hubble takes 40 minutes. I'm most confident about the last one, since that's what I ended up completing.

## Announcing tern

After a lot of iterations, I now have a typeahead search service, situated on the same server as my other services. There's still a very small throttle on it, but try typing into [shelf.cafe](https://shelf.cafe) now. It's instant. The search results don't exactly match Bluesky or waow.tech, but the ranking is done with similar data. Tern has a slight preference for handles over display names, compared to the others.

There's a landing page up for the live service at [https://typeahead.cove.town](https://typeahead.cove.town), where you can try it out from your location, showing your latency per search. It also comes with some overall statistics, most of them provided by [tally](https://tangled.org/jola.dev/tally). The search service is hosted on Hetzner in Finland, and fronted by [bunny.net](https://bunny.net?ref=f0l8865b7g), which also means this is a fully hosted in the EU. I've tested response times across the world though and thanks to the CDN it performs similar or better than existing services across the world. Your mileage may vary!

It's a tantivy search engine, with ranking using account age and followers count, the index takes up about 12GB of disk space., account data fetched from Bluesky's AppView. The account store is Fjall, using about 5.4GB of disk space at the time of writing. It discovers new account events over the jetstream, using [slingshot.cove.town](https://slingshot.cove.town) to turn the did into a handle. This is also how it keeps handles fresh, after updating your handle it should be reflected within seconds. Account metadata like follower counts are fetched from the Bluesky AppView, and refreshed on a weekly basis.

It uses about 1.5GB of memory under normal operations, that's just the parts of the index kept in memory, but you could restrict it to less. With the index and account store, it uses about 20GB of disk, but it needs more when rebuilding the index since the old index keeps serving requests until the new is finished. On my server it's using about 10% of a single core of CPU, that's mostly from index rebuilds and stale account enrichment.

Search latency is about 30ms at p99, and p50 is 100µs. That's the internal measurement, though, what's more interesting is you actual live experience across the network. Try it out at [typeahead.cove.town](https://typeahead.cove.town) and let me know how it is!

## Future improvements

Us having more alternatives for solving problems is a great sign of the health of the atproto ecosystem. You can see it in the different options for discovering all the dids on the protocol, between Jetstream v2, plc exports, and Hubble. Now you have another typeahead search service to choose from, that's a good thing!

I have no immediate plans to add the additional features that [waow.tech]'s search has, like filtering by PDS. I would however like to explore using non-Bluesky data for scoring to help active accounts that are not on Bluesky rank better. I think looking at something like the count of backlinks for a did, which constellation can give, would be an interesting proxy for relevance. It would require something like a constant ~70 RPS on `/links/all` to keep that updated on a weekly basis for all the accounts in the atmosphere though.

Account ranking is hard and I'm not sure there's a right answer, but I'm curious how you feel about [typeahead.cove.town](https://typeahead.cove.town). Is it returning the right things? I even made a little comparison site where you can see results side by side, [hosted on wisp.place](https://johanna.wisp.place/typeahead-comparison.html).

For questions and thoughts on [cove.town](https://cove.town) ping me at [@jola.dev](https://bsky.app/profile/jola.dev) or [@cove.town](https://bsky.app/profile/cove.town). Take a look at the tern codebase on [Github](https://github.com/joladev/tern) or [Tangled](https://tangled.org/jola.dev/tern). And have fun!
