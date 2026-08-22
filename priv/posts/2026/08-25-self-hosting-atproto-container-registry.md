%{
  title: "Self-hosting an atproto container registry",
  author: "Johanna Larsson",
  tags: ~w(atproto self-hosting hold container registry),
  description: "How to get the atcr.io hold component up and running for atproto container registry fun."
}
---

This is a part of a series of blog posts on self-hosting atproto components. The previous ones are [Self-hosting your PDS] and [Self-hosting and Tangled](https://jola.dev/posts/self-hosting-your-pds).

[atcr.io](http://atcr.io) is a container registry on [atproto](https://atproto.com/), it’s a place where you can push your Docker and other container images to, and then fetch them and run them in just about any place, from a local [Docker Compose,](https://docs.docker.com/compose/) to hosted services like [Railway](https://railway.com/), or self-hosted PaaSs like [Dokploy](https://dokploy.com/).

While [atcr.io](http://atcr.io) offers a free managed registry server, you can also run your own, called the `hold`. So we will!

## The guide

As usual, you need to have a domain or subdomain ready to point at your hold. You’ll also need one for your self-hosted object storage, if you’re not using an existing one. Let’s assume you have `s3.example.com` and `hold.example.com`.

Okay, if you’ve read the previous parts you know we start with the Caddy file. You’ll also need a `.env` file, we’ll get some of the values for it later.

```bash
hold.example.com {
    reverse_proxy hold:8080
}

s3.example.com {
    reverse_proxy garage:3900
}
```

```bash
GARAGE_RPC_SECRET=<openssl rand -hex 32>
AWS_ACCESS_KEY_ID=<fill in later in the guide>
AWS_SECRET_ACCESS_KEY=<fill in later in the guide>
```

Ok, next up, storage. While the manifests live on atproto, the layers themselves are heavy and the hold offloads them to object storage. This means we need an S3 compatible server set up before we can get to the hold. You could use a paid service here, like [Scaleway](https://www.scaleway.com/en/) or [Hetzner](https://hetzner.cloud/?ref=SjrsM8GhyYOl) (referral link for €20 credits), but if we have a server with space and resources to spare, why not use it. In the wake of the minio drama [Garage](https://garagehq.deuxfleurs.fr/) has established itself as a great alternative.

So we set up our Garage config `garage.toml`.

```toml
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"

replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".garage"
```

This is a fairly minimal setup without replication, feel free to explore some of the options you can put in here. But it’s enough to get us started. We’ve got one more config file to go, the one for the hold itself, `config-hold.yml`.

```bash
storage:
  region: garage
  bucket: atcr-blobs
  endpoint: https://s3.example.com

server:
  public_url: https://hold.example.com
  public: false

registration:
  owner_did: did:plc:YOUR_DID
```

The storage config has to match up against garage, or the alternative S3 provider you choose. Make sure the public URL matches the domain you’ve set up. The `owner_did` needs to match up against a real account that you have, it will be the owner of the hold and the account you log into the admin panel with to add more users. I’ve defaulted to `public: false` here but set it to true if you want other logged in [atcr.io](http://atcr.io) users to be able to pull your images. Only members can write, even with `public: true`.

Next up, the compose definition. I’ll just give you the whole thing in one go: caddy, garage, and hold.

```bash
services:
  garage:
    image: dxflrs/garage:v2.3.0
    restart: always
    environment:
      - GARAGE_RPC_SECRET=${GARAGE_RPC_SECRET}   # openssl rand -hex 32
    volumes:
      - ./garage.toml:/etc/garage.toml:ro
      - garage_meta:/var/lib/garage/meta
      - garage_data:/var/lib/garage/data
  hold:
    build:
      context: https://tangled.org/evan.jarrett.net/at-container-registry.git#v0.1.4
      dockerfile: Dockerfile.hold
    command: ["serve", "--config", "/config.yml"]
    restart: always
    environment:
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    volumes:
      - ./config-hold.yml:/config.yml:ro
      - hold_data:/var/lib/atcr-hold
  caddy:
    image: caddy:2
    restart: always
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
volumes:
  hold_data:
  caddy_data:
  garage_meta:
  garage_data:
```

We’re going to have to sequence things here to get it all up and running. First up, we need to start the S3 server and create the bucket and credentials.

```bash
docker compose up -d garage                                    # 1. storage first
docker exec $(docker ps -qf name=garage) /garage -c /etc/garage.toml bucket create atcr-blobs
docker exec $(docker ps -qf name=garage) /garage -c /etc/garage.toml key create hold-key
docker exec $(docker ps -qf name=garage) /garage -c /etc/garage.toml bucket allow --read --write atcr-blobs --key hold-key
```

Okay, take the access key ID and the secret and add them to the `.env` file you set up earlier. And then you can start the rest

```bash
docker compose up -d
```

Assuming everything starts fine, you can now go to `https://hold.example.com/admin` and log in with the owner account you specified. In the admin panel you can then add whatever other users you want to have access to it, you’ll need the did for each account, and you can choose what permissions they have. Take a look at the Relays page too, you’ll need the relays to pick up your hold for things to work well. This can take a bit of time. Crawls are requested automatically on startup, but you can also request one here.

To start using the hold you have to select it. Log in to [atcr.io](http://atcr.io) and go to settings. If your hold doesn’t show up, either you’re not a member of the hold, or the relays haven’t picked it up yet. 

Once you’ve got it selected, try a `docker login atcr.io` and a `docker push atcr.io/user/image`.

## Wrapping up and CDN

As usual, you’ll want to set up backups. You’re hosting the data, you don’t want to lose it.

There are a bunch of interesting variations on this set up that you can try out. For example, hold also supports specifying a PLC DID, instead of defaulting the a web DID. With a web DID you can’t move your hold to a new domain, something to keep in mind. If you do specify a PLC DID, unless you also provide a `HOLD_DATABASE_ROTATION_KEY`, it will print the rotation key in logs on first startup. Grab it or lose it. Also there’s a lot you can configure on the garage side, including setting up a CDN like the excellent [bunny.net](https://bunny.net/?ref=f0l8865b7g) to speed things up. 

It’s a fairly low lift to add, signing up to [bunny.net](https://bunny.net/?ref=f0l8865b7g) and creating a pull zone. Leave all the default settings in place and grab the subdomain they give you, or set up your own one. Then update the `config-hold.yml` to add `pull_zone`:

```bash
storage:
  pull_zone: <pull zone url>
  # ... rest
```

That’s it. It just works.

Take a look at how [cove.town](http://cove.town) is set up if you want some more inspiration. Next up I’m gonna do a little “putting it all together” blog post, where we build docker images on our spindle and push them to our hold. It’ll be real neat.
