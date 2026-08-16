%{
  title: "Self-hosting your PDS",
  author: "Johanna Larsson",
  tags: ~w(atproto self-hosting pds),
  description: "How to set up your own atproto Personal Data Server using tranquil-pds and docker compose, walking you through it step by step."
}
---

I take a lot of pleasure in running my own services. Self-hosting is a lot of fun and I keep accumulating more and more things on my server, from a feed reader to uptime monitoring (as backup to [larm.dev](https://larm.dev)), not to mention all of my toy projects.

I’ve been writing a lot about [atproto](https://atproto.com/) recently and it’s frankly a very fertile area for self-hosting. Not only are there lots of open source components you can run, but the nature of atproto decentralization means that you can run your own services while seamlessly participating in shared systems. For example, you can run your own PDS (Personal Data Server) and create an account on it, and then log into Bluesky and post and participate with everyone else. Your account will work across the ATmosphere.

So, let’s talk about what it takes to self-host a PDS. Follow along and by the end of this you're posting on Bluesky from your own self-hosted account.

## tranquil-pds

There are multiple PDS implementations out there. The original and probably most common one is the [Bluesky reference PDS](https://github.com/bluesky-social/pds), but when I was researching options I came across one that matches the reference feature set but adds useful features on top: [tranquil-pds](https://tangled.org/tranquil.farm/tranquil-pds). It’s implemented in Rust, comes with a nice admin panel, invite code management, passkeys, granular OAuth scopes, and a lot more.

There are plenty of instructions in the repo, but they’re a bit spread out, and some parts can get a bit tricky around wildcard certs, so I thought I’d write a bit of a getting started guide. This will be very similar to the setup I have for [cove.town](https://tangled.org/cove.town/cove.town), with some simplifications.

There are a few things going on under the hood here that are worth highlighting:

- The PDS holds the account repo, or in other words, all of your on-protocol data. This can be things like blog posts, Bluesky posts, standard reader reading history, book reviews, and much more. It also holds the blobs you upload, like images and videos.
- Handles need a verification method, either through DNS or a web server that responds on `.well-known/atproto-did`. The PDS is built to handle this, but it requires getting the right DNS records and TLS certificates in place.
- As long as you make backups and [set up a rotation key](https://jola.dev/posts/taking-control-atproto-account), self-hosting your atproto account is fairly safe, you can recover from things like the PDS going down or accidentally deleting the database. So make backups.

## Getting started

Before we get to the code, we need a few things.

1. A domain that you can add records to. You’re going to need to set up an `A` or `CNAME` wildcard record pointing at your server. For example, if your domain is `example.com`, the record would be `*.example.com`. This is because the accounts will get handles like `alice.example.com`. Alternatively, if you’re happy to add each subdomain manually, you can skip the wildcard record and just create `pds.example.com`.
2. A server with Docker or something similar installed. We’re going to use it to set up a compose. You can use alternatives like podman, but this guide will focus on Docker.

Armed with those two things, we’re ready to go.

## TLS termination

A PDS needs to serve HTTPS traffic, and it needs to be able to serve that traffic on subdomains. That means the subdomains need TLS certificates issued. Caddy (unlike Traefik) comes with the ability to provision TLS certificates for domains on demand, so we’ll start by setting this up.

If you’ve opted not to use a DNS wildcard, and instead manually create each record for each account, you can skip the `on_demand_tls` and hardcode the subdomains instead.

Create a file called `Caddyfile` where you want the project.

```hcl
{
    on_demand_tls {
        interval 2m
        burst 5
    }
}
*.example.com {
    reverse_proxy pds:3000
    tls {
        on_demand
    }
}
```

## The PDS itself

This is mostly an adapted version of the example compose from the Tangled repo, with the configuration moved into the environment section. Create `compose.yml` with this content.

```yaml
services:
  pds:
    image: atcr.io/tranquil.farm/tranquil-pds:latest
    restart: always
    environment:
      SERVER_HOST: "[::]"
      PDS_HOSTNAME: pds.example.com
      PDS_USER_HANDLE_DOMAINS: example.com
      INVITE_CODE_REQUIRED: "true"
      DATABASE_URL: postgres://tranquil_pds:${POSTGRES_PASSWORD}@db:5432/pds
      JWT_SECRET: ${JWT_SECRET}
      MASTER_KEY: ${MASTER_KEY}
      DPOP_SECRET: ${DPOP_SECRET}
      DISABLE_ACCOUNT_VERIFICATION_GATE: "true"
    volumes:
      - blob_data:/var/lib/tranquil-pds/blobs
    depends_on: [db]
  db:
    image: postgres:18-alpine
    restart: always
    environment:
      POSTGRES_USER: tranquil_pds
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: pds
    volumes:
      - pg_data:/var/lib/postgresql
  caddy:
    image: caddy:2
    restart: always
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
volumes:
  blob_data:
  pg_data:
  caddy_data:
```

You’ll want to replace the `example.com` domain name with your own, and you’re going to need to set up some secrets. Create a file called `.env` and fill it with these keys, running `openssl rand -base64 48` for each and filling in the value.

```
JWT_SECRET=<openssl rand -base64 48>
MASTER_KEY=<openssl rand -base64 48>
DPOP_SECRET=<openssl rand -base64 48>
POSTGRES_PASSWORD=<openssl rand -base64 48>
```

Ok, that should be everything now. Try to start it up!

`docker compose up -d`

Take a look at the start up logs, they contain an important thing: your first invite code.

`docker compose logs pds | grep -i invite`

Now go to your PDS and create your account, choosing password or passkey for auth. Paste the invite code in the appropriate field. Congratulations, you now have your very own self-hosted atproto identity. Check it out!

`curl https://you.example.com/.well-known/atproto-did`

Assuming everything has gone to plan, that should return your did, looking something like `did:plc:string`. And next, for the real test, try logging into a service that uses atproto OAuth, like [Bluesky](https://bsky.app/), [annot.at](https://annot.at), or [Standard Reader](https://standard-reader.app/).

Now create a bunch of accounts for all the things you need! Get some cool custom domains and update your handles through the tranquil-pds dashboard. Live your best life.

## How you can tighten this up

The first thing you might want to consider to do is set up a verification flow. The compose has `DISABLE_ACCOUNT_VERIFICATION_GATE: "true"` which means you can sign up without email or another verification channel, but without those channels you can’t do things like password resets or PLC 2FA tokens. Tranquil supports a few different good options, including Discord and email. For the former you need to create a Discord bot, invite it to your server, and set `DISCORD_BOT_TOKEN`. And for the latter you’ll need these values.

```yaml
   MAIL_FROM_ADDRESS: pds@example.com
   MAIL_SMARTHOST_HOST: smtp.provider.com
   MAIL_SMARTHOST_PORT: "587"
   MAIL_SMARTHOST_USERNAME: ...
   MAIL_SMARTHOST_PASSWORD: ...
   MAIL_REQUIRE_TLS: "true"
```

And there’s a lot more you could do to improve on this set up. Check out the [cove.town repo](https://tangled.org/cove.town/cove.town) for a more complete reference. Some examples of things you could do:

- Move the blob storage to object storage, either self-hosting something like [Garage](https://garagehq.deuxfleurs.fr/), or going for a managed solution like [Scaleway](https://scaleway.com/) or [Hetzner](https://hetzner.cloud/?ref=SjrsM8GhyYOl) (referral link for €20 credits).
- Set up backups of your Postgres DB and the blob volume. You can also do manual backups of your accounts using tools like [goat](https://github.com/bluesky-social/goat).
- Proper secret management, instead of maintaining a `.env` file you could look at some secret management tools, like [OpenBao](https://openbao.org/).
- Instead of a plain compose, run a self-hosted PaaS like [Dokploy](https://dokploy.com/).

Additionally tranquil-pds supports advanced features like running multiple instances clustered, and the [maintainers are super friendly](https://tangled.org/tranquil.farm/tranquil-pds/pulls/240/round/2)!

The world’s your [oyster.cafe](https://mu.social/profile/oyster.cafe).
