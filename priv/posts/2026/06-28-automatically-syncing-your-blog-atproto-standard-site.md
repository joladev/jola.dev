%{
  title: "Automatically syncing your blog to atproto and standard.site",
  author: "Johanna Larsson",
  tags: ~w(blog atproto standardsite elixir phoenix oss),
  description: "A little love letter to the small web, to the now classic technology of RSS, to the future of atproto, and to the people who share for the joy of sharing."
}
---

In a [previous post](https://jola.dev/posts/publishing-your-blog) I wrote about publishing blog posts using the new [standard.site](http://standard.site) lexicon on [atproto](https://atproto.com/docs), which makes your content discoverable using readers like [Standard Reader](https://standard-reader.app/), and the originators of the lexicon, [pckt](https://pckt.blog/), [Offprint](https://offprint.app/), and [Leaflet](https://leaflet.pub/). As a little bonus, you also get a special post preview frame on Bluesky. This is a genuinely interesting technology and the community seems to be growing quickly, with lots of little apps and tools popping up everywhere. Not to mention the [Summer of Standard.site promotion](https://bsky.social/about/blog/06-22-2026-summer-of-standard-site) where Bluesky gives you a 25% discount across the standard.site blogging apps.

Although atproto was created by Bluesky to drive their social network, the protocol itself is actually provider agnostic and there are already lots of alternative servers, like [mu.social](http://mu.social) by Eurosky, and [you can migrate your data across](https://move.eurosky.tech/)! Lots of services are popping up that use atproto to provide you with functionality, while letting you own your data. 

At the end of my [previous post](https://jola.dev/posts/publishing-your-blog) I mention not wanting to be too clever with getting it working, but that I’d probably not stop there. And I didn’t! I played around with some different ideas for automating posting my blog to atproto and eventually settled on using RSS as a discovery mechanism. The goal is to support syncing across any blog with a feed to atproto, with minimal effort.

So the design is:

1. You log in and create your publication or select an existing one.
2. You select your feed.
3. Prove ownership of your blog with `/.well-known/site.standard.publication`.
4. Discover all your posts through your feed.
5. Publish the ones you want.
6. Set up automatic publishing of new posts discovered off of your feed.
7. Update existing posts when the content changes.

## annot.at

I’m writing the code in public on [Tangled](https://tangled.org/jola.dev/annot.at) with a Github mirror. This is very much a work in progress but feel free to take a look. I’m also hosting it at [annot.at](http://annot.at), which is the instance I use to manage my own blog. You’re very welcome to try it out, but remember it’s under active development and may change over time. I’ve implemented 1-5 of the list above, although I think I’ll go back to some earlier parts and redesign them. I have a tendency to figure things out by just starting to type, I’m not the kind of programmer who can just build the perfect version in their mind. I have to start writing the code to figure it out.

But ok, let’s do a little whirlwind tour of how it works.

### OAuth

Before you can use the app, you need to authenticate. The easiest way to implement auth against atproto is using handle + password, but you obviously don’t want to hand your actual password over to every app. Bluesky offer [app passwords](https://bsky.app/settings/app-passwords) that are intended for third party apps. Logging in with one of those doesn’t allow the most destructive actions like deleting the account, and can be deleted from the account, basically revoking access.

A much nicer experience is using OAuth to let the user auth against their own provider, for example Bluesky or Eurosky, and then using the access token to take actions for the user, same as you would use Google or Github OAuth. However, atproto OAuth is decentralized, there’s nowhere to go to get your client ID and client secret. Going through the whole thing deserves its own blog post, but you can read about [atproto OAuth in the Bluesky docs](https://docs.bsky.app/docs/advanced-guides/oauth-client) or take a [look at my implementation in annot.at](https://tangled.org/jola.dev/annot.at/blob/main/lib/annot_at_web/controllers/auth_controller.ex). 

You wouldn’t normally want to write this kind of code yourself, but there’s no battle-hardened atproto OAuth library for Elixir yet. I used [atex](https://github.com/cometsh/atex) as a reference while implementing this.

### atproto XRPC

Now that we have an access token we can start making requests against the user’s [PDS](https://atproto.com/guides/self-hosting). atproto is built on XRPC, basically a modern day SOAP XML, except with JSON. Each request contains the **repo** that it’s targeting (your account), the **collection** (the resource, such as `site.standard.publication`), and the **operation** you want to execute (eg `getRecord)` ).

This means we can now implement operations like `create_publication`, `list_publications`, `create_document`, etc. You can see the [annot.at](http://annot.at) implementations for those [here](https://tangled.org/jola.dev/annot.at/blob/main/lib/annot_at/atproto/standard_site.ex).

### Feed parsing

Steps 2 and 4 from the master plan above require us to both be able to discover feeds from a blog, and to fetch and parse the feed itself. So far I’ve only implemented RSS parsing, will need to go back and add Atom and other formats too, but RSS covers a lot of the internet as is.

To discover the feed we need to be able to take a URL, like https://jola.dev, and find feeds listed in that document. Feeds are declared using a link tag in the head of the document, for example `<link rel="alternate" type="application/rss+xml" href="/feed.xml" />`. There can be multiple feeds on the same page. To parse the links out of the document I use LazyHTML, which is a dependency of Phoenix mainly used for testing, but since I had it I figured I might as well use it.

Parsing the XML feed is a bit bigger. I’m not looking to prematurely optimize, but considering how feeds can easily have hundreds of posts in them, each one with `content:encoded`, we can’t cut any corners here. Using the incredible Saxy library I wrote an RSS parser that gets what I need and nothing else. I looked at some existing parsers like [gluttony](https://github.com/thiagomajesk/gluttony/tree/master) for reference, but the version [I wrote is much smaller](https://tangled.org/jola.dev/annot.at/blob/main/lib/annot_at/feeds/rss.ex). My plan is to add another one of these for Atom.

### What comes next

The current version of [annot.at](http://annot.at) can discover your feed and publish your posts for you, but there’s still a lot left to do. I still don’t publish the post content, which would by the RSS standard be HTML. There’s a community content type, `org.wordpress.html`, for HTML content, but no “blessed” path to publishing the content as rich text. And I’m still not grabbing the Open Graph image for each page to set the icon on the document.

Not to mention the biggest feature: actually syncing automatically by polling your feed. But I’m working on it! I believe that atproto will just continue to grow as people find more interesting use cases for it, and the fact that your data belongs to you and can follow you around, the fact that you can actually host your own data on your own PDS, but still use all these amazing services, is incredible.

Feel free to check out the code and tinker with it, and maybe use it for reference to build your own cool atproto apps. You can even run it locally and login, since it doesn’t require a client ID or client secret, and use it to publish your blog. If you prefer not to run it yourself, try out [annot.at](https://annot.at).
