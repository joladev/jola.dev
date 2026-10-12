%{
  title: "Making your own atproto backlink index",
  author: "Johanna Larsson",
  tags: ~w(elixir atproto shelf.cafe),
  description: "I built an atproto backlink index using Latch and Kite, and I sped it up with some neat bloom filter and erlang atomics action."
}
---

For [shelf.cafe](http://shelf.cafe) I wanted to aggregate interesting conversations about a blog post in one place, so people can chat and learn. As part of this, I wanted to “discover” every time a blog post had been shared somewhere else, like Bluesky, and surface that. This is commonly referred to as a “backlink”. While building this out I tackled some very interesting technical challenges so here’s a little write up that covers looking up existing atproto backlinks, subscribing to the jetstream to monitor for new ones, and how to efficiently determine whether we care about a specific URL being mentioned somewhere on atproto.

## the jetstream

The Bluesky team, in collaboration with the community, have and are developing some really interesting infrastructure that enables building on top of it with minimal effort. One of the most important pieces is the jetstream, which recently had a rework and a v2 version. I’ll just be talking about v2, but a lot of the existing ecosystem still use the original jetstream, and a lot of libraries have not added support for the new version yet.

The jetstream servers support anyone anonymously subscribing to a websocket and immediately getting records and updates happening, all of the ones happening on the protocol right now. The basic design is that the user’s PDS owns the data and updates to it. The PDS exposes a firehose endpoint and requests known relays crawl it. The relays subscribe to all the PDSs and echo the updates happening on the PDSs. This is how atproto achieves federation of a decentralized protocol. You could crawl every PDS out there yourself, but that would not be very efficient.

The jetstream is like the relay, but it produces JSON instead of CAR archives and stuff, making it much more accessible and easy to get up and running with, with the tradeoff that you can’t cryptographically verify each record. You instead have to trust the jetstream, which seems reasonable enough for this use case, although it would be interesting to run your own.

## Creating a Bluesky post backlink indexer with Kite

While working on this I implemented the jetstream subscriber side of things in a self-contained way because I had an ulterior motive, I wanted to break it out as a library.  After having had it run in production for long enough to prove that it was sound, I broke it out as a standalone library. It’s available and already works really well, [https://tangled.org/jola.dev/kite](https://tangled.org/jola.dev/kite). It supports filters on collections and dids, zstd compression using the native OTP 28 module, and automatic and seamless failover if one jetstream server is down.

So, let’s look at using the library to create our backlink index. Let’s focus on Bluesky posts because they’re fairly uniform and contains tons of URLs. Here’s a [sample fixture](https://tangled.org/strings/did:plc:bvraa6gajy4tfr3eh2sisdkr/3mxmafjfqtk22) to look at. We can ignore the text and focus on facets and embeds, the fixture has both. You could have a URL in the text content, but it would render as plain text in Bluesky, and you rarely see that happening. Most links are posted through their UI which will represent it as a facet or embed, depending on how it’s created. Embedded URLs render as a preview below the post.

Let’s go through it bit by bit. First we need to be able to extract URLs from a post.

```elixir
  def extract_urls(post) do
    facets = post["facets"]

    embed_url = embed_url(post)

    facet_urls =
      Enum.flat_map(facets || [], fn facet ->
        Enum.map(facet["features"] || [], fn feature ->
          if feature["$type"] == "app.bsky.richtext.facet#link" do
            feature["uri"]
          end
        end)
      end)

    Enum.reject([embed_url | facet_urls], &is_nil/1)
  end

  defp embed_url(%{"embed" => %{"external" => %{"uri" => uri}}}) do
    uri
  end

  defp embed_url(_), do: nil
```

Extracts both facets and embeds. Embeds can be done with a straightforward pattern match, with facets we have to iterate through and check each one. The result should be a list of URLs.

This is written in a slightly defensive way on purpose. Although there is support in the spec for PDSs to validate records before accepting them, this is far from a guarantee. And a failure in the Kite subscriber crashes it, which means it restarts and reconnects and tries to replay the message because the cursor has not advanced. So it’s a good idea to apply some defensive thinking when writing logic that runs in the subscriber. Find the balance between that and making your code look sad.

Okay, next let’s look at the overall structure of the subscriber.

```elixir
defmodule Shelf.Catalog.Backlink.Indexer do
  use Kite,
    kinds: [:commit],
    collections: ["app.bsky.feed.post"]

  @cursor "backlink"

  def get_cursor, do: Cursors.get_cursor(@cursor)

  def put_cursor(seq), do: Cursors.put_cursor(@cursor, seq)

  def handle_event(%{"operation" => "create"} = commit, context) do
    %{"record" => record, "did" => did} = commit
    urls = extract_urls(record)

    Enum.map(urls, fn url ->
      # if we track the URL in our system, store it, otherwise discard
    end)
  end
  
  def handle_event(_other, _context) do
    :ok
  end
end

```

Kite takes care of most of the stuff for us here. We specify that we only care about `commit`, which gives us create/update/delete of records, and filter it down to the Bluesky post collection. We also define cursors so we can track our progress and recover on crashes and restarts. You can skip the cursors if you want, the callbacks are optional, but if you don’t have them any restart means losing events. The underlying implementation of `Cursor.get_cursor` and `Cursor.put_cursor` here is just reading and writing from a DB table.

`handle_event` is the meat of the logic, this is where the magic happens. We get a “commit”, which contains a record. We’ve already looked at the logic to extract URLs from the record, so next we need to fill in the `Enum.map` and store backlinks. Oh, and there’s a second `handle_event` to handle `create` and `delete` operations since we’re ignoring those for this example.

I’m skipping over the persistence functions, let’s just assume `Catalog` exists and it offers `apply_backlink` and `url_exists?` and does the underlying operations with the database. In the case of [shelf.cafe](http://shelf.cafe) they’re just Ecto under the hood, talking to PostgresQL. The exact things you want to store for your backlinks may differ but here I’ve gone for `url`, `source_uri` (the at-uri of the record), `author_did`, and `created_at`. I’m using [Latch](https://tangled.org/jola.dev/latch/) to construct the at-uri, and as I mentioned earlier we can’t trust the record itself, so this is extra defensive around the `created_at`.

We first check if the linked URL exists in our system. I only need to record backlinks for content that has been submitted on [shelf.cafe](http://shelf.cafe), but you could remove the check if you just wanted to record everything you see!

```elixir
    Enum.map(urls, fn url ->
      if Catalog.url_exists?(url) do
        case Catalog.apply_backlink(%{
               url: url,
               source_uri: uri(commit),
               author_did: did,
               created_at: created_at(record["createdAt"])
             }) do
          {:ok, _backlink} ->
            Logger.info("Created a backlink", backlink: inspect(backlink))

          {:error, changeset} ->
            Logger.info("Failed to create a backlink", backlink: inspect(changeset))
        end
      end
    end)
  end

  defp uri(%{"did" => did, "collection" => collection, "rkey" => rkey}) do
    at_uri = Latch.AtURI.new!(did, collection, rkey)
    Latch.AtURI.to_string(at_uri)
  end

  defp created_at(nil), do: nil

  defp created_at(created_at) do
    case DateTime.from_iso8601(created_at) do
      {:ok, datetime, _offset} ->
        datetime

      {:error, _reason} ->
        nil
    end
  end
```

Ok, and that’s it. Honestly, that’ll work. You might want to implement a handler for the `delete` operation too, so you clean up backlinks that don’t exist anymore, and there’s all kinds of polish you can do on top of this. But it works as is.

## Unnecessary optimizations, aka bloom filters

When building this I couldn’t help but think about how it would scale and where it would break. The handler runs in the subscriber, so it has to process items as fast as the jetstream produces them, although it’s fine if it’s temporarily behind as long as it catches up within ~24h. Under extreme circumstances we could enqueue the processing to be done out of band, basically adding a queue, but that kinda just moves the overload from falling behind the jetstream to building a backlog of events to process. [Queues don’t fix overload](https://ferd.ca/queues-don-t-fix-overload.html). I don’t want to mess with the part where we write to the datastore, but… we could mess with the `url_exists?` check!

The way it’s implemented now, it goes to the DB and checks if the there are any [shelf.cafe](http://shelf.cafe) submissions that link to the given URL. If there is, we store the backlink. Otherwise we skip. In the case of postgres we can make this plenty fast with a non-unique index on the URL column on submissions. But what’s even faster? Bloom filters!

The magic of bloom filters is that they can, taking up a relatively small amount of space, tell you whether something absolutely does not exist in it. Every single time the bloom filter says a given URL does not exist in our records, we can skip going to the database. When it gives a positive result, we still have to double check, because it can’t accurately tell you whether something *does* exist. But guess what, an estimated 99.99999999% of URLs posted on Bluesky don’t exist as submissions on [shelf.cafe](http://shelf.cafe). The perfect excuse to do *real computer science*.

First, let’s implement our bloom filter module. We’re gonna rely on the very cool Erlang module of `:atomics`, which give you concurrent lock-free access to a set of shared 64 bit integers. We’re just going to be reading from our single subscriber (for now, who knows what the future will bring), but we are going to *write* to it from an undefined number of concurrent callers. Reads will heavily outnumber writes, but we could have multiple overlapping writes coming from other processes. The writes can come both from someone submitting through the app, and through records created directly on a user's PDS.

```elixir
defmodule BloomFilter do
  import Bitwise

  @word_size 64

  defstruct [:ref, :mask, :probes]

  def new(bits, probes) when band(bits, bits - 1) == 0 do
    words = div(bits, @word_size)

    %__MODULE__{
      ref: :atomics.new(words, signed: false),
      mask: bits - 1,
      probes: probes
    }
  end

  def put(%__MODULE__{ref: ref} = filter, term) do
    positions = indexes(filter, term)

    Enum.each(positions, &set_bit(ref, &1))
  end

  def member?(%__MODULE__{ref: ref} = filter, term) do
    positions = indexes(filter, term)

    Enum.all?(positions, &bit_set?(ref, &1))
  end

  defp indexes(%__MODULE__{mask: mask, probes: probes}, term) do
    <<base::64, step::64, _rest::binary>> = :crypto.hash(:sha256, term)

    Enum.map(0..(probes - 1), fn probe ->
      base + probe * step &&& mask
    end)
  end

  defp set_bit(ref, index) do
    word = word_index(index)
    bit = bit_mask(index)

    set_word(ref, word, bit)
  end

  defp set_word(ref, word, bit) do
    current = :atomics.get(ref, word)
    desired = current ||| bit

    if current == desired do
      :ok
    else
      case :atomics.compare_exchange(ref, word, current, desired) do
        :ok -> :ok
        _changed -> set_word(ref, word, bit)
      end
    end
  end

  defp bit_set?(ref, index) do
    word = word_index(index)
    bit = bit_mask(index)
    value = :atomics.get(ref, word)

    (value &&& bit) != 0
  end

  defp word_index(index) do
    div(index, @word_size) + 1
  end

  defp bit_mask(index) do
    1 <<< rem(index, @word_size)
  end
end
```

This could be a lot denser, but I tried to write it in a way where each operation (mostly) get its own line to make it easier to read through. It’s also not optimized as a general purpose bloom filter, but it works very well for this use case.

Of course, this is Elixir, someone’s gotta own this thing, even though access will be shared by many processes. So let’s define a `GenServer` to own it and prepare it on startup.

```elixir
defmodule URLCache do
  use GenServer

  @bits 67_108_864
  @probes 5

  def put_url(url) do
    BloomFilter.put(filter(name), url)
  end

  def exists?(url) do
    BloomFilter.member?(filter(name), url) and Catalog.url_exists?(url)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    filter = BloomFilter.new(@bits, @probes)
    :persistent_term.put(__MODULE__, filter)

    {:ok, [], {:continue, :load}}
  end

  @impl GenServer
  def handle_continue(:load, state) do
    Repo.transaction(fn ->
      Catalog.url_stream()
      |> Stream.each(&BloomFilter.put(filter, &1))
      |> Stream.run()
    end)
    {:noreply, state}
  end

  defp filter(name) do
    :persistent_term.get(name)
  end
end

```

So this creates the filter with some sensible sizing, roughly based on the incredibly reasonable assumption that [shelf.cafe](http://shelf.cafe) will blow up and become bigger than any other link aggregators. The things of note here are that number one, the filter struct, containing the reference to the `:atomics`, is stored in `:persistent_term`. `:persistent_term` lets you store data in a way that any process can access it, across your instance, without paying a copying cost. The downside to it is that every write causes a global garbage collection. Luckily we only ever call `:persistent_term.put` once.

Secondly I backfill the bloom filter with every single URL from the database on startup. Because I can’t help myself, this is done streaming instead of just reading it all into memory. Through the magic of bloom filters the data stored in memory is *much* smaller than the actual size of all the URLs. The cache needs to be kept up to date, so it exposes a `put_url` operation, and of course it has to support lookups, so it exposes `exists?`. The implementation here goes straight to the DB if the result is positive, to check if it really does exist, but you could also keep that out of the cache if you want it purer.

It swaps into our existing subscriber cleanly, replacing `Catalog.url_exists?` with `URLCache.exists?`.

## Backfilling backlinks

Of course, there’s still a gap in our coverage. We only start recording backlinks for URLs once we become aware of them, any interesting Bluesky posts from before that are absent. Luckily, someone has thought about this, and there’s a community infrastructure project that maintains a massive backlink index at [https://constellation.microcosm.blue/](https://constellation.microcosm.blue/). This is part of the [microcosm](https://www.microcosm.blue/) project by [@bad-example.com](https://northsky.app/profile/bad-example.com). As it’s community infrastructure, we don’t want to misuse it, but this seems like a reasonable use case.

When we see a new submission URL, we hit constellation’s `GET /links/all` endpoint to discover what kind of backlinks exist. This tells us which kinds of backlinks exist, like `embed.external.uri`. And then for each one, we hit `GET /xrpc/blue.microcosm.links.getBacklinks` which gives us everything we need to construct our backlinks: `did`, `rkey`, `collection`. Except, we don’t get a `created_at`. That’s not a huge deal, but it would be nice to be able to sort backlinks by age. There’s a neat trick we can apply here though, because Bluesky posts use [TIDs](https://atproto.com/specs/tid) as record keys, and each TID contain a timestamp. The documentation clearly states you can’t trust the timestamp in it, of course it can be set to anything. For example, using [Latch.TID.at_time/1](https://latch.hexdocs.pm/0.9.0/Latch.TID.html#at_time/2) we can create a TID for an arbitrary datetime. But importantly, you can’t trust `created_at` either, it can also be set to anything. Comes with being a decentralized protocol. 

So just like we can use `Latch` to create a TID from a datetime, we can also extract the datetime from a given TID! Calling [Latch.TID.to_datetime/1](https://latch.hexdocs.pm/0.9.0/Latch.TID.html#at_time/2) gives us our `created_at` timestamp back. Or at least a reasonable approximation of one!

I took all that logic and wrapped it in an Oban worker that’s enqueued whenever a new URL is submitted and I treat it as best effort, it’s not like I can complain if constellation is down!

ps oh by the way I could skip the `/links/all` and go straight to `getBacklinks` since I know the set of “sources” in advance, but it wouldn’t necessarily lead to a reduction in requests since `/links/all` lets me skip anything that doesn’t exist.

## What comes next

[shelf.cafe](http://shelf.cafe) currently ingests Bluesky post backlinks, but in the future I’m looking at doing the same for other lexicons, like standard.site. Although with the content being optional and different blogging providers structuring their data differently, it’s a trickier one!

Building [shelf.cafe](http://shelf.cafe) is taking me through all these really fascinating technical challenges. I also have to take a moment to recognize the incredible potential atproto has. I know I tend towards evangelizing it, but it’s just such a great experience building on top of and comes with all these great secondary effects, like how easy it is to build a backlink index. So go build your own!
