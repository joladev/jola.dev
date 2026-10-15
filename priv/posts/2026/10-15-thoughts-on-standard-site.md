%{
  title: "thoughts on standard.site",
  author: "Johanna Larsson",
  tags: ~w(atproto standard.site annot.at community lexicon),
  description: "standard.site is a huge success as an atproto community lexicon, but there's some stuff we can improve, let's talk about it!"
}
---

I’ve previously written about [publishing your blog to standard.site](https://jola.dev/posts/publishing-your-blog) and I created [annot.at](http://annot.at), a service for [publishing static blog content to the protocol](https://jola.dev/posts/automatically-syncing-your-blog-atproto-standard-site). I’m a huge fan of the lexicon and the community around it, it’s incredibly cool that it opens the door to sites that make that content discoverable like [Standard Reader](https://standard-reader.app/), and it has the potential to replace RSS feeds for subscribing to blog posts. It’s a great initiative and I’m very happy it exists.

I finally listened to the OffProtocol podcast episode [“Why don’t we just do this together”](https://atproto.com/off-protocol/do-this-together-standard-site), with the originators of standard.site. And it got me thinking, as someone who has been using the lexicon, publishing things, and who has [built a service](http://annot.at) that publishes RSS feed content to it, bridging the technologies, **I do have some thoughts on how we can maybe improve things as a community.**

## Record keys have to be TIDs

This isn’t immediately obvious if your content originates from the protocol, as is the case for services like leaflet.pub, pckt.blog, or offprint.app, or if you’re just building your own site where the record is the source of truth. But if you’re bridging ecosystems, like syncing RSS feeds to the protocol, or if you just want to add [standard.site](http://standard.site) to your static blog, things can get a little bit awkward.

It wasn’t immediately obvious to me either, it’s not super clear from the [standard.site](http://standard.site) docs site, but the record key for a document *has to be a [TID](https://atproto.com/specs/tid)*. If you’re not familiar with TIDs, or **Timestamp Identifiers**, they’re generated compact strings that represent a 64 bit integer and they contain a timestamp. We don’t need to go into more detail, or talk about the fun things you can do with them, other than to say that you would generally *generate* one and then track it as the record key, or ID, of your document. For a static site though, this process is not straightforward.

Traditionally the only thing that kinda identifies a static site blog post is the slug. You’re probably even using the slug as your guid in your RSS feed! But to integrate with standard.site, you need to also generate a TID. You can do this a few different ways, but all of them are a bit awkward. One is to generate it and optionally create the record up front, maybe from the command line, and then store it in the frontmatter of your post, before you publish your blog post. Alternatively, you use a deterministic TID implementation that does something like taking the `published_at` from the frontmatter and then adding a hash of the slug as a clock ID, or something to that effect, giving you an exact TID that you can generate at build time that’s the same every time.

Why do you need to store it or make it deterministic? Because your blog post has to contain the tag `<link rel="site.standard.document" href="at://did:plc:you/site.standard.document/tidrkey" />` to prove the connection between the record and the page.

[This has been an issue for a while on the lexicon repo.](https://tangled.org/standard.site/lexicons/issues/7) To me the answer seems clear here, we should remove the type restriction on record keys for documents and let people use what they want, including things like post slugs. This would significantly simplify setups for syncing "traditional" static blogs to the protocol.

## Link vs meta

Speaking of that link proving the connection between the record and page, this is an example of the problem the Bluesky team hit on with the IETF standardization process of at-uris. [They’re not valid URLs](https://bnewbold.leaflet.pub/3mph4hzvbdc2v). And the `href` attribute must have a URL. I don't think this was commonly known when standard.site was drafted up, and so the specification, as I mentioned above, requires a `link` tag for verification reasons.

And Bluesky follows that spec and uses this `link` tag to validate [standard.site](http://standard.site) documents, so for now you’ll want to have one, but we should find an approach that doesn’t conflict with the existing standards. [@chrisshank.com](https://northsky.app/profile/chrisshank.com) [proposed](https://discourse.atmosphere.community/t/mapping-web-pages-to-canonical-at-records/904) a [standard](https://tangled.org/chrisshank.com/at-tags/) for linking HTML pages to atproto records in a generic way that seems to fit the bill. The IETF conversation will probably take a while to to conclude, but to me this seems like a very reasonable approach to moving us forward, that should at least be discussed as an alternative for proving the connection between the record and the page.

## Open union for content, but no standard format

The podcast gives a lot of great insight into some of the design choices behind standard.site, and I especially appreciate the thought that went into the content field. I can definitely see the attraction in coming up with the “perfect” content format and locking it in. The team did something much better, they kept content an open union, letting anyone define their own formats and tagging their content.

This means a [standard.site](http://standard.site) document can have content that is `at.markpub.markdown` while another one has `com.wordpress.html`, and it also means each of the blog apps participating in the lexicon development can use their own custom formats, while using the record to store the content, keeping it all on the protocol.

But what if we have both? What if we as a community put forth a standardized generic format, and keep the open union. That means you can use your own neat formats where you want them, but we also create space for the community to use a shared format where it makes sense. It’s not straightforward to agree on what the generic format should be, but I also don’t think it’s impossible to find one. Rich text formats is a very well researched field after all!

And that brings us to the next thing.

## Non-standard formats means no inter-operability

I will never stop shouting out [@bad-example.com](https://northsky.app/profile/bad-example.com) for the wonderful community infrastructure projects they develop and maintain. [microcosm](https://tangled.org/microcosm.blue/microcosm-rs/) is the gift that keeps on giving. One of the neatest services they maintain is [constellation](https://constellation.microcosm.blue/). This is a protocol-wide backlink index. You can try it out right there on that page and it has example queries pre-configured. By ingesting all the data of the protocol as it happens, tracking every time one record is linking to another, it’s able to answer interesting questions like “what Bluesky posts link to this blog post?”. If you want to learn more about what you can do with backlinks, read my post on [Building an atproto backlink index](https://jola.dev/posts/building-atproto-backlink-index). 

But constellation only works for data it can interact with. If the `content` field is not set on the record (it’s not a required field and not all blog apps set it), or if the content is not accessible, then constellation can not index it. That’s a big upside of the AT protocol we’re missing out on. That’s a lot of interoperability and discoverability that we’ve given up. We can have WebMention-like features for free, if we stay accessible.

There are a lot of trade-offs here and it’s not a simple question of just doing x, but I think this kind of discoverability should be a goal of standard.site.

## The conflict at the core of the lexicon

People have blogs for lots of reasons. Some blog as a past-time, where it really doesn’t matter if anyone reads it. Others blog to take part in a “small-web” community. Many of the most prolific bloggers do it because they directly profit, through revenue, or indirectly profit through community support, sponsorships, or just establishing their name in the community.

Looking at the last group, their interest in atproto and [standard.site](http://standard.site) is maybe primarily as a discovery mechanism. People can find their content through websites like Standard Reader and through other “recent blog post” feeds, linking back to their blog and bringing in more traffic. Other associated records like `site.standard.graph.subscription` and `site.standard.graph.recommend` also have the potential to lead to more visitors to the blog.

Equally, blog apps like leaflet.pub, pckt.blog, and offprint.app, want visitors to come to their services. The more users come through, the more discover their offerings, leading to more users and activity.

And that’s where the fundamental conflict of it shines through. Putting your content on the protocol, making it public and accessible, is at odds with bringing visitors to your site. Because now readers can now read it anywhere. If Standard Reader can render your blog post fully on their side, [standard.site](http://standard.site) is no longer a way to attract more visitors. [If anything, it’s at risk at taking them away!](https://bsky.app/profile/brookie.blog/post/3mr2cvvdijk2p)

Please don’t get me wrong, everyone involved is just trying to provide a good experience for their users. There’s no fault here. But it’s worth having this conversation. I’m a little bit conflicted myself. The posts on this blog do render on Standard Reader, as I publish them with the `com.wordpress.html` format. I’m kinda competing with myself here and it’s… awkward?

I don’t have any answers really.

## Moving forward

Hopefully kicking off or reviving some of these conversations, or just generally bringing some awareness, and that that can help the community in some way. I love what standard.site has brought us already and I’m excited to see what the future will bring.

Thank you to [@standard.site](https://bsky.app/profile/standard.site).
