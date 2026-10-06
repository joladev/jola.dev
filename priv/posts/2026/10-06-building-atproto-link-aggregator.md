%{
  title: "Building an atproto link aggregator",
  author: "Johanna Larsson",
  tags: ~w(elixir atproto shelf.cafe),
  description: "As a little passion project I built an atproto link aggregator service in Elixir and this post goes into some detail about why I'm doing this and how it works."
}
---

I love reading a good online article or blog post. A lot of the content I like to read tends to be tech, but it’s not always. There are few things better than finding a gem produced by a subject matter expert in whatever topic, someone who made the effort of taking all the knowledge in their field and presenting it in an accessible way. Or in other words, I can read any number of articles on the late bronze age collapse. Just keep them coming.

I make an effort of adding interesting blogs to [my feed reader](https://github.com/joladev/miniflux), and fortunately a significant number of blogs have feeds, but in practice most of the content I read comes from [Bluesky links](https://northsky.app/), [bubbles.town](https://bubbles.town/), [lobste.rs](https://lobste.rs/), and with some incredible self-control stopping myself from reading the comments, [Hacker News](https://news.ycombinator.com/). Each one has its own vibe, and none of them match exactly what I’m looking for, but I can usually find one or two things to read each day. Bubbles especially is interesting because it’s not driven by submissions, instead it has a list of feeds that it polls to find new content, and it uses Mastodon as a “backend” for the posts, comments, and votes.

And that got me thinking about what the same thing would look like on [atproto](https://atproto.com/).

## shelf.cafe

I had been meaning to build more of a “proper” atproto app, one with its own lexicon and AppView, ingesting content from a jetstream, all the cool stuff. So I did! [shelf.cafe](http://shelf.cafe) is live and kicking, and there’s already 14K+ links posted. There’s so much to share about how this works, so I’m just gonna start with the purpose: **shelf is an experiment in building an atproto link aggregator and creating a community around it**. I’m trying to take a little bit of the best of each world. Like Bubbles, Shelf has a list of feeds that it follows (more on that later) and automatically posts content from. But unlike Bubbles, Shelf supports making individual submissions as well. Otherwise it works a bit like you’d expect. You can comment and upvote, and there’s a front page that shows the highest voted content, with decay applied to keep it fresh.

I’ve also cared a lot about performance and being mindful of people’s data limits. The front page loads in about 250ms for me, although your experience may vary based on cache status, location, and more. Rendering the front page only requires ~170kB of data transfer on an uncached load, less after the first page load. This is a mostly server-side rendered app, on purpose. Everything on [shelf.cafe](http://shelf.cafe) is designed to handle a lot more load than its actually receiving (I can't help myself), but more importantly, it should be pretty snappy even on a mobile phone with a poor connection.

Note that [shelf.cafe](http://shelf.cafe) is not the first atproto link aggregator, there are already projects like [https://frontpage.fyi/](https://frontpage.fyi/). However, its front page rarely changes. Which I imagine is how most attempts at link aggregators end up. Shelf might end up in the same place, but I have given some thought to how I might be able to get around this.

## Bootstrapping a link sharing community

When trying to build a link aggregator from scratch, the hardest part is getting content and engagement. Taking inspiration from Bubbles and following existing feeds and automatically posting new content gives us the former, we can build up lots of interesting content, but the latter is harder. Half the reason we use link aggregators is to read the comments, but there won’t be any comments until there’s a community. The classic chicken or egg problem.

What I came up with to tackle this is that I built a backlink index. I process all the posts on Bluesky, live as they happen, and record every instance of someone mentioning a URL that had been submitted to Shelf. So if I post a link to this blog post on Bluesky, that post and any threads relating to it are automatically rendered in Shelf in the comment section! It’s obviously not a replacement for a community of engaged and caring people, but it does give you something to read!

So the remaining thing [shelf.cafe](http://shelf.cafe) needs are upvotes. I’d rather wait for those to come naturally!

## The algorithm and moderation

[shelf.cafe](http://shelf.cafe) uses the moderation tools that are built into atproto itself. Although subject to change, it currently tracks four labelers, [Bluesky Moderation](https://northsky.app/profile/moderation.bsky.app), [Blacksky Moderation](https://northsky.app/profile/moderation.blacksky.app), [Northsky Moderation](https://northsky.app/profile/moderation.northsky.social), and [Skywatch Blue](https://northsky.app/profile/skywatch.blue). Labelers are independent moderation services that label content on the protocol. Bluesky uses this to moderate posts, but it’s a generic concept that works across the protocol. In other words, Bluesky posts backlinks, submissions, and accounts that trigger labels such as `spam` or `scam` are automatically hidden by the shelf.cafe AppView. For now Shelf can also apply “local” bans to make moderation easier, but the plan is to move this to a proper labeler as well. For what it’s worth, that’s never been used outside of hiding the millions of Hacker News bots that post backlinks on Bluesky.

And for the algorithm, I wanted to keep it simple.

`Score = Votes ^ 0.8 / (Age + 2) ^ 1.8`

Or in plainer language, the ranking of an item is based on the number of votes, where each vote is less powerful than the last, divided by the age of the item, where the impact of the age increases over time. This is a fairly standard ranking algorithm when you want the content of the front page to refresh every day, but still means items with more votes can stick around for longer.

## The blog list

shelf.cafe, like Bubbles, has a list of blogs that it follows. I actually started with the Bubbles list, which is public at [https://bubbles.town/blogs.opml](https://bubbles.town/blogs.opml), but after setting it all up I kind of realized that I hadn't thought this through. The `/new` page had lots of posts on it, but the kind of content that I wanted to see on the front page was getting drowned out with automated posts, weekly notes, and daily meditations. Nothing wrong with any of it, but if I want shelf.cafe to stand out I have to do something at least a little bit different.

I'm still working on a new curated list of blogs. It's already looking a lot better, but there's more to be done. The goal is not to filter it down to just topics I'm interested in, but to give more space for longer form posts and write ups. Once I've got it into a good place I'm gonna add a `/blogs.opml` endpoint that matches the Bubbles one. If you want to submit your blog for inclusion let me know, but I haven't written up proper criteria yet.

Although I also see a potential future where Shelf does not auto-post from followed blogs.

## Vote on Shelf widget

[shelf.cafe](http://shelf.cafe) exposes an XRPC (basically just a JSON endpoint) that’s CORS-enabled and can be called from any website. This means you can add a “Vote on Shelf” button on your blog too, showing the up to date vote count. The endpoint returns all of the submissions that have been made for your URL, since Shelf allows reposting. To make a “Vote on Shelf” widget what we need to do is query that endpoint, and if it returns one or more items, pick the one we want to link to. The reason that it can return multiple is that a URL can be submitted to Shelf multiple times. You can find a live example of a widget like this on this very page, both at the top of this post and at the post footer. For this blog I chose to link to the highest-voted item. 

**I’ve got a version of this widget you can just paste into your own site.** It only has limited configuration right now, but I’ll add more over time. There will not be breaking changes to this widget, but I might add more options in the future.

```html
<!-- Add this on your page where you want the widget -->
<div class="vote-on-shelf"></div>

<!-- Add this in <head> or at the bottom of your HTML document -->
<script src="https://cdn.shelf.cafe/scripts/widget.js?vsn=1" defer></script>
```

And that’s it. It’ll pull the script from a CDN-hosted link and execute it, showing a widget like what you see on this blog post, like `6 ▲ on shelf.cafe`. You can override the URL that it uses with `data-url="<url>"`, but it will default to the current page. If you’d prefer to make your own widget, that’s totally doable. To demystify this, let’s take a look at how that script works.

It starts by finding the `div` that you set up as the “anchor” and makes a request to the public Shelf API, checks if there are any items in the result, and picks the one with the highest vote count and displays that vote count. Clicking the link takes you to the item in Shelf where you can vote. If the URL has no items associated with it, it instead shows a link to go submit the item, prefilling the URL.

```jsx
function initializeShelfVotes() {
  document.querySelectorAll('.vote-on-shelf').forEach(el => {
    const url = el.getAttribute('data-url') || location.href.split('#')[0];
    fetch(`https://shelf.cafe/xrpc/getItems?url=${encodeURIComponent(url)}`)
      .then(r => r.json())
      .then(d => {
        const items = d?.data?.items ?? [];
        if (!items.length) {
          el.innerHTML = `<a href="https://shelf.cafe/items/new?url=${encodeURIComponent(url)}" target="_blank" rel="noopener noreferrer" style="color:#b8623f;text-decoration:none">▲ post on shelf</a>`;
          return;
        }
        const item = el.getAttribute('data-link') === 'newest'
          ? items[0]
          : items.reduce((a, b) => (b.vote_count > a.vote_count ? b : a));
        el.innerHTML = `
        <a href="${item.shelf_url}" target="_blank" rel="noopener noreferrer" style="color:#888;text-decoration:none">
          ${item.vote_count || ''} <span style="color:#b8623f">▲</span> on shelf.cafe
        </a>`;
      })
      .catch(() => el.remove());
  });
}

initializeShelfVotes();
```

You’re welcome to do whatever you want with this snippet, make it yours! And the endpoint returns other info too that you may want to display in some way, here’s an example response:

```json
{
  "data": {
    "items": [
      {
        "title": "AI is antithetical to learning",
        "uri": "at://did:plc:bvraa6gajy4tfr3eh2sisdkr/cafe.shelf.item/3mw473xtga25v",
        "source": "jola.dev",
        "url": "https://jola.dev/posts/ai-antithetical-learning",
        "inserted_at": "2026-09-22T12:11:24Z",
        "cid": "bafyreibe6lc5y3bfvj7lbr63dsaue43knc52bz2nfz6w4desqm2aczcbei",
        "created_at": "2026-09-22T12:11:23Z",
        "did": "did:plc:bvraa6gajy4tfr3eh2sisdkr",
        "rkey": "3mw473xtga25v",
        "vote_count": 2,
        "comment_count": 0,
        "backlink_count": 2,
        "shelf_url": "https://shelf.cafe/items/did:plc:bvraa6gajy4tfr3eh2sisdkr/3mw473xtga25v"
      }
    ]
  }
}
```

Of course you’re able to make requests to this endpoint from the backend as well, `https://shelf.cafe/xrpc/getItems?url=<url>`. It does not require authentication, but there is a default rate limit of 60 requests per IP per minute which is also subject to change. If you call it from your server you may want to cache/store the results and not make a request every time you render a page.

## So what makes it atproto

Well, apart from the XRPC endpoint, the thing that makes it atproto is that all the data required to render the front page is available on the protocol. As an example, [here is a recent item I submitted](https://pdsls.dev/at://did:plc:bvraa6gajy4tfr3eh2sisdkr/cafe.shelf.item/3mwv6m5x3o2n5) and [here’s the shelf page for the same item.](https://shelf.cafe/items/did:plc:bvraa6gajy4tfr3eh2sisdkr/3mwv6m5x3o2n5) The lexicons are also published [here](https://pdsls.dev/at://did:plc:xo5sew2ggwpnnfmqk2cx2swa/com.atproto.lexicon.schema).

This means you can make your own app and render your own front page, including applying your own ranking algorithm. The data on the protocol is the raw data, uninfluenced by what shelf.cafe is displaying. In the future I may add more endpoints for others to query my AppView, but as it is, there’s nothing stopping you from building your own.

This also means that I could drop Shelf’s database and then recreate it by pulling down all the atproto records from the protocol. Of course I’d have to rebuild the backlink index as well, and fetch all the labels. But I would be able to recreate the AppView if required.

Backlinks are a neat topic by the way, and I want to dig deeper into that in a future post that focuses on the technical aspects of Shelf. But in short, I use a Jetstream subscriber filtered on Bluesky posts that match URLs that have been submitted, and for backfills I use [Constellation](https://constellation.microcosm.blue/) by the excellent [@bad-example.com](https://northsky.app/profile/bad-example.com). The result is that you can see all the conversations across Bluesky when you click on a link on Shelf.

Another cool effect from this is that you don’t actually need to use the website to submit something to it, and you can set up integrations to automatically post your content. As a little proof of concept, let’s look at what posting an item would look like using the [goat](https://github.com/bluesky-social/goat) command line tool. To follow the steps after this you need to first log into an atproto account using `goat account login`.

Here’s a sample item record as JSON: 

```json
{
  "$type": "cafe.shelf.item",
  "url": "https://example.com/post",
  "title": "Some post",
  "source": "example.com",
  "createdAt": "2026-10-03T18:00:00Z"
}
```

Replace the values with what you want to submit, copy the whole thing, and run: `pbpaste | goat record create -n -`. Now you’ve submitted a Shelf item. Congratulations! Go to [https://shelf.cafe/new](https://shelf.cafe/new) to admire your handiwork. It should show up within a second or so, even with atproto’s decentralized nature.

This of course implies the possibility of creating a [shelf.cafe](http://shelf.cafe) TUI app. I’ll leave that as an exercise for the reader. Seriously, that’d be really cool.

Oh, and as a final *atproto* note. Although the idea of community lexicons and interoperability is really cool, I think for me the core concept of atproto is that each user owns their own data. Not as a selling feature, but as a foundation for building systems. It forces you to think about things in a different way, and for apps like [shelf.cafe](http://shelf.cafe) where all the data required to rebuild the AppView lives on the protocol, it means that there’s no vendor lock-in. Shelf’s lexicons have not been designed with community approval. And that’s ok. If we ever get to a point where we need a new lexicon, we’ll figure it out.

Either way, you own your data. If one day you want to “migrate” to another link aggregator, you or they can write a script that does that. And that’s really neat.

## What’s next

I’ve got a lot more to write about here. How backlinks work probably deserves its own blog post. Not to mention how [shelf.cafe](http://shelf.cafe) ingests data from the protocol and the philosophy of writing to a local AppView but treating the PDSs of the world as the source of truth. Or how shelf.cafe can render the frontpage in 250ms.

Also this isn’t the headline feature, and it doesn’t necessarily matter that much, but [shelf.cafe](http://shelf.cafe) is hand-written code. I spend enough time with agents at work. This is me doing something different. I’m enjoying software engineering, the way it used to be, and I’m doing my best to put care and attention into every little thing. That’s not meant as a criticism of people who use agents to write code. I’ve done a lot of that myself. I just don’t want to do that here.

I’m really curious to see what [shelf.cafe](http://shelf.cafe) turns into.
