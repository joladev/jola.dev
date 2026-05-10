%{
  title: "bunnyx: a bunny.net elixir client library",
  author: "Johanna Larsson",
  tags: ~w(elixir bunny bunnynet opensource),
  description: "A best-practice Elixir library for interacting with the bunny.net API"
}
---

[bunny.net](https://bunny.net?ref=f0l8865b7g) is a CDN service provider with lots of extra bells and whistles, most similar to Cloudflare in feature set, but maintained by a European company. Unlike Cloudflare, they’re not free, but they are cheap enough that it doesn’t really matter. Unless you’re making very heavy use of their service, you won’t be paying more than the minimum €1 each month. And as a paying customer, your relationship is a lot different than it is as a non-paying user of Cloudflare.

I’ve been using bunny.net for a lot of things I’ve been building recently, including the landing page and status page feature for [Larm](https://larm.dev), the uptime monitoring project I’ve been working on. As part of that work, I wanted a feature rich client library for interacting with the extensive bunny.net API.

# Introducing: [bunnyx](https://github.com/joladev/bunnyx)

This is not the first Elixir library for interacting with the bunny API. I ended up rolling my own because I wanted something that was flexible enough to fit into my system design. The version that I built into Larm wasn’t as feature rich as what I’ve ended up open sourcing here, but once I had something going, I just got into the flow of testing through the API endpoints end to end, and documenting and verifying each one. And suddenly I had a whole feature complete library.

[bunnyx](https://github.com/joladev/bunnyx) is built with a special focus on [the Elixir library guidelines.](https://hexdocs.pm/elixir/1.20.0-rc.4/design-anti-patterns.html#using-application-configuration-for-libraries) This means that it avoids certain things: there’s no application config and there’s no application supervisor starting automatically. Instead, it follows the design of the excellent `Req` library by Wojtek Mach. Not to mention that it internally makes heavy use of it!

Additionally I invested a lot of time and energy into the test suite. Apart from extensive unit test coverage, I built a series of Livebook runbooks that you can feed an API key into and execute each and every request scenario, even running through the whole book to automatically create, read, update, and delete, resources. This means you can easily verify the behavior of `bunnyx` against the actual bunny API.

# Quickstart

```elixir
# Before running this, you'll need:
# - A bunny.net account and API key (from the Account API section of the dashboard)
# - A storage region code — DE, NY, LA, or SG. See:
#   https://docs.bunny.net/reference/storagezonepublic_add
# - A globally unique storage zone name
# - A globally unique pull zone name
# - The file you want to upload

client = Bunnyx.new(api_key: "sk-...")

# 1. Create a storage zone to hold the files
{:ok, storage_zone} = Bunnyx.StorageZone.create(client, name: "my-assets", region: "DE")

# 2. Point a pull zone at the storage zone so the files are served from the CDN
{:ok, pull_zone} = Bunnyx.PullZone.create(client,
  name: "my-assets-cdn",
  storage_zone_id: storage_zone.id
)

# 3. Upload a file via the separate storage client (its own auth and base URL)
storage = Bunnyx.Storage.new(storage_key: storage_zone.password, zone: storage_zone.name)
{:ok, nil} = Bunnyx.Storage.put(storage, "/images/logo.png", File.read!("logo.png"))

cdn_url = "https://#{pull_zone.name}.b-cdn.net/images/logo.png"
# Your file is now live at cdn_url

# 4. Replace the file, then purge so the new version is served immediately
{:ok, nil} = Bunnyx.Storage.put(storage, "/images/logo.png", File.read!("new-logo.png"))
{:ok, nil} = Bunnyx.Purge.url(client, cdn_url)
```

If you want to wrap things up for convenience, create your own wrapper module.

```elixir
defmodule MyApp.Bunny do
  def create_pullzone(name, origin_url) do
    client = Bunnyx.new(api_key: api_key!())

    Bunnyx.PullZone.create(client, name: name, origin_url: origin_url)
   end

  def api_key! do
    Application.fetch_env!(:my_app, :bunny_api_key)
  end
end
```

# Feature set

**Main API (`Bunnyx.new/1`)**

- **CDN**: `PullZone` (CRUD, hostnames, SSL, edge rules, referrers, IP blocking, statistics)
- **DNS**: `DnsZone` (CRUD, DNSSEC, export/import, statistics), `DnsRecord` (add, update, delete)
- **Storage management**: `StorageZone` (CRUD, statistics, password reset)
- **Video libraries**: `VideoLibrary` (CRUD, API keys, watermarks, referrers, DRM stats)
- **Cache**: `Purge` (URL and pull zone purging)
- **Security**: `Shield` (zones, WAF rules, rate limiting, access lists, bot detection, metrics, API Guardian)
- **Compute**: `EdgeScript` (scripts, code, releases, secrets, variables), `MagicContainers` (apps, registries, containers, endpoints, volumes)
- **Account**: `Billing` (details, summary, invoices), `Account` (affiliate, audit log, search), `ApiKey`, `Logging` (CDN + origin logs)
- **Reference**: `Statistics` (global), `Country`, `Region`

**Separate clients**

- **Edge storage** (`Bunnyx.Storage`): upload, download, delete, list files
- **S3** (`Bunnyx.S3`): PUT, GET, DELETE, HEAD, COPY, ListObjectsV2, multipart uploads
- **Stream** (`Bunnyx.Stream`): video CRUD, upload, fetch, collections, captions, thumbnails, re-encode, transcription, smart actions, analytics, oEmbed

# What next

First of all I want to give a huge shoutout to Wojtek Mach for setting an incredible example for the Elixir community on how to design libraries. Req is one of my favorite reference repos and I keep coming back to it and discovering new gems.

Secondly, I want to say that [Bunny CDN](https://bunny.net?ref=f0l8865b7g) is a great service and I appreciate having a genuinely powerful alternative to Cloudflare, provided by a European company.

[Check out the repo, try out the library, and let me know how you get on!](https://github.com/joladev/bunnyx)
