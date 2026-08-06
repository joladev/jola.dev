%{
  title: "Latch - an Elixir atproto OAuth library",
  author: "Johanna Larsson",
  tags: ~w(atproto elixir oauth),
  description: "Introducing Latch, an idiomatic elixir atproto OAuth library and client, built for flexibility and correctness."
}
---

As part of building a service for [automatically publishing blog posts from RSS feeds into atproto's standard.site lexicon](https://annot.at), I implemented atproto OAuth for logging in and getting access tokens to publish for the user. This means that any user with an atproto account, whether they created it on Bluesky, Eurosky, or Blacksky, or any of the other Personal Data Servers available, can log in to your service. Atproto OAuth does not require pre-registering clients with a service, one implementation works across the entire ecosystem.

The OAuth implementation is based on the [2.1 specification with some still in-draft extensions](https://oauth.net/2.1/), and comes with some quirks compared to what you'd expect from older generations of OAuth. For example, access tokens can't be used as is, they need to come with a [DPoP](https://datatracker.ietf.org/doc/html/rfc9449) (demonstrating proof of possession) header signed for the specific request you're making, limiting what the access token can be used for if stolen. Additionally it includes [PAR (push authorization request)](https://www.rfc-editor.org/rfc/rfc9126.html) and some other fun stuff like [PKCE](https://oauth.net/2/pkce/), but maybe one of the most significant being [CIMD](https://datatracker.ietf.org/doc/draft-ietf-oauth-client-id-metadata-document/) (client ID metadata document), the thing that lets you prove who you are as a client without registering in advance.

The goal of Latch is to provide an idiomatic Elixir implementation that deals with all of this for you, while maintaining flexibility and enabling things like setting up multiple OAuth clients in the same project, and starting them ad-hoc on command. I [have strong feelings about designing Elixir libraries](https://jola.dev/posts/let-libraries-be-libraries) and I've tried to apply the best practices here.

## Quickstart

_For a complete Phoenix example integration of Latch, take a look at [the source code for annot.at](https://tangled.org/jola.dev/annot.at)._

Add Latch to your project.

```elixir
def deps do
  [
    {:latch, "~> 0.4.0"}
  ]
end
```

Create a Latch Store module for storing in-progress requests and access tokens. You can create your own Store implementation by implementing the `Latch.Store` behavior, for example here's an [Ecto backed one](https://tangled.org/jola.dev/annot.at/blob/main/lib/annot_at/latch_store.ex) from [annot.at](https://annot.at).

```elixir
defmodule MyApp.LatchStore do
  use Latch.Store.ETS
end
```

Add it and your Latch instance to your supervision tree.

```elixir
children = [
  {MyApp.LatchStore, []},
  {Latch,
    name: MyApp.Latch,
    mode: :confidential, # Latch also supports `:localhost` for local dev, and `:public` for browser based clients
    store: MyApp.LatchStore,
    client_id_path: "/oauth-client-metadata.json", # you can select any path here, but this is a good default
    redirect_uri_path: "/auth/callback", # match your callback path
    base_url_fn: &MyAppWeb.Endpoint/1,
    scope: "atproto",
    # signing key is required for confidential apps, create with:
    # `mix run -e '{_, jwk} = JOSE.JWK.to_map(JOSE.JWK.generate_key({:ec, "P-256"})); IO.puts(Jason.encode!(jwk))'`
    signing_key: System.fetch_env!("ATPROTO_CLIENT_PRIVATE_JWK")}
]
```

Set up routes to serve the CIMD (client ID metadata document) at `/oauth-client-metadata.json` and your callback route.

```elixir
  get "/oauth-client-metadata.json", AuthController, :client_metadata
  get "/auth/callback", AuthController, :callback
```

and implement your `AuthController` with:

```elixir
  def client_metadata(conn, _params) do
    json(conn, Latch.client_metadata(MyApp.Latch))
  end
  
  def callback(conn, params) do
    case Latch.callback(AnnotAt.Latch, params) do
      {:ok, %{did: did, handle: handle}} ->
        # store the user in session
  
      ...
    end
  end
```

Now the rest of it is fairly recognizable if you've done OAuth before. Call authorize when a user has passed their handle to log in, redirect them to the URL you get back, and then provide a callback URL to finish the flow.

```elixir
# call when the user clicks log in
{:ok, url} = Latch.authorize(MyApp.Latch, "alice.bsky.social")
# send to the user to the url

# expose a callback endpoint and call callback
{:ok, %{did: did, handle: handle}} = Latch.callback(MyApp.Latch, conn.params)
# and you're done, the access token lives in Latch
```

Now you can hit private endpoints or write to the user's [atproto PDS](https://atproto.com/guides/self-hosting#pds), according to the scopes you requested. Here's are some example requests. Note that access tokens are managed and refreshed automatically by the library.

```elixir
{:ok,
  %{
    "uri" => "at://did:plc:abc123/app.bsky.feed.post/3k2...",
    "cid" => "bafyreid...",
    "value" => %{
      "$type" => "app.bsky.feed.post",
      "text" => "Hello atproto",
      "createdAt" => "2026-07-31T12:00:00.000Z"
    }
  }} =
  Latch.query(MyApp.Latch, did, "com.atproto.repo.getRecord",
    params: [
      repo: did,
      collection: "app.bsky.feed.post",
      rkey: "3k2..."
    ]
  )

{:ok,
  %{
    "uri" => "at://did:plc:abc123/app.bsky.feed.post/3k5...",
    "cid" => "bafyreig..."
  }} =
  Latch.procedure(MyApp.Latch, did, "com.atproto.repo.createRecord", %{
    repo: did,
    collection: "app.bsky.feed.post",
    record: %{text: "Hello atproto", createdAt: DateTime.utc_now()}
  })
```

I've previously written a bit about atproto and Latch on [https://blog.annot.at](https://blog.annot.at) and I'm planning on writing more about it here, especially around how atproto OAuth works, and some of the design decisions that went into making `Latch`.

Here are some links:

- Github [https://github.com/joladev/latch](https://github.com/joladev/latch)
- Tangled [https://tangled.org/jola.dev/latch](https://github.com/joladev/latch)
- hex.pm [https://hex.pm/packages/latch](https://hex.pm/packages/latch)
- HexDocs [https://latch.hexdocs.pm/readme.html](https://latch.hexdocs.pm/readme.html)

Let me know how you find it! Really excited to see more Elixir atproto apps!
