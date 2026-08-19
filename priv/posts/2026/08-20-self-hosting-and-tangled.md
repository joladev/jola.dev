%{
  title: "Self-hosting and Tangled",
  author: "Johanna Larsson",
  tags: ~w(atproto self-hosting tangled knot spindle),
  description: "Tangled is a Github alternative built on atproto that lets you self-host your own repos and workflows, while still participating in a shared community. Here's how you get set up."
}
---

Following the blog post on [how to self-host a PDS (Personal Data Server) for atproto](https://jola.dev/posts/self-hosting-your-pds), having your accounts live on your own server, while still being able to interact with apps like [Bluesky](https://bsky.app/) and [pckt.blog](https://pckt.blog), I wanted to write a little about how to do the same for [Tangled](https://tangled.org/).

Caveat: the Tangled team are working on a new generation of components, including [knot2](https://tangled.org/tangled.org/core/tree/master/knot2), [mill](https://tangled.org/tangled.org/core/tree/1adde466290bdc74e2a18f23592a03975be11a92/spindle/mill), and the new appview based on [bobbin](https://blog.tangled.org/bobbin/). There will be some form of migration path, but it's all in active development.

Tangled is basically Github on atproto. In other words, Tangled offers repo hosting, CI actions, and social coding features. Where they differ is that Tangled doesn’t have private repos yet (we’re all waiting with baited breath for [permissioned data](https://github.com/bluesky-social/proposals/tree/main/0016-permissioned-data) to land), and that Tangled allows you to self-host your infrastructure while still participating in the social features. If you’re hosting a [forgejo](https://forgejo.org/) or [gitea](https://about.gitea.com/) instance, or have been thinking about it, this is really the killer feature. The other self-hosted Github alternatives have the side-effect of “isolating” you, it’s harder to find your repo because there’s no shared location where you find all self-hosted instances, and to interact with your repo, creating issues or PRs, users have to create a new account for every single instance. With Tangled you can run your own knot and spindle, but users can find and interact with them on the shared appview.

So let’s take a look at what it takes to self-host the two current Tangled components: knot and spindle. Note that this guide just lays out one way of running them, you’ll want to tweak things to make sense for you.

## Knot, the repository server

To follow along with this guide, you’ll need a domain name you can point at the app, and a server with a public IP. I’ll be using Docker Compose but [the docs also contain instructions for NixOS.](https://docs.tangled.org/knot-self-hosting-guide)

Just like with the PDS, we set up a reverse proxy to terminate TLS, I’m just using Caddy here because it doesn’t require much config. Create `Caddyfile` in your project directory with this content.

```elixir
knot.example.com {
   reverse_proxy knot:5555
}
```

Unlike the PDS, there’s not that much to configure here. `KNOT_SERVER_OWNER` should be set to the DID of the atproto account you want to own the knot. That account can then grant access to other accounts. Nobody can use your knot without first being invited.

The biggest thing to highlight here is the port you’re opening on the knot itself. The reverse proxy handles API requests, but the main job of the knot is reading and writing repositories, and that’s going to happen over SSH. The knot comes with an embedded OpenSSH server that only supports a very small number of operations, related to git. The example below puts that open port on `:2222`, but if you’ve already moved your SSH port on your server away from `:22`, or you use something like Tailscale SSH which doesn’t use that port, you can let the knot own `:22`.

```elixir
services:
  knot:
    image: atcr.io/tangled.org/knot:latest
    restart: always
    environment:
      KNOT_SERVER_HOSTNAME: knot.example.com
      KNOT_SERVER_OWNER: did:plc:YOUR_DID
      KNOT_SERVER_DB_PATH: /app/knotserver.db
      KNOT_REPO_SCAN_PATH: /home/git/repositories
      KNOT_SERVER_INTERNAL_LISTEN_ADDR: localhost:5444
    volumes:
      - ./keys:/etc/ssh/keys
      - ./repositories:/home/git/repositories
      - ./server:/app
    ports:
      - "2222:22"

  caddy:
    image: caddy:2
    restart: always
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data

volumes:
  caddy_data:
```

The `atcr.io/tangled.org/knot:latest` image is community maintained and `linux/amd64` only, and so if you prefer to build your own, or run an ARM server like I do, take a look at [the workflow in cove.town](https://tangled.org/cove.town/cove.town/blob/main/.tangled/workflows/knot.yml). I’m planning to write a guide on setting up an atcr.io hold for a self-hosted container registry too! Ok, next start the compose.

```bash
docker compose up -d
```

Once your server is up and running and you’ve verified you can see the `This is a knot server` message when you go to it in your browser. Take a look at [https://knot.cove.town](https://knot.cove.town) for an example of what you should be seeing. Okay, now it’s time to register it in the Tangled appview.

Log in to Tangled with your owner account, bonus points if it’s an account running on your own PDS, and go to Settings → Knots. Here you can register your knot by putting in the domain name. Make sure it says “Verified”, and add any additional members you want. Now when you, or any of those members, go to create a new repository you’ll see your knot as a hosting option.

Note that if you don’t run your knot on `:22` you will not be able to copy paste the git-over-SSH path that’s shown after creating a repo, you need to build your remote URLs yourself, like `ssh://git@knot.example.com:2222/did:plc:string`.

## Spindle, the workflow runner

Now that you have your repository set up let’s talk CI. Tangled provides official spindles to run your workflows on, but if you’re reading this, you’re probably curious about how to run your own. Apart from it being *fun*, you might want to do this to get access to more powerful machines, specific architectures, [secret management with OpenBao](https://docs.tangled.org/spindles#secrets-with-openbao), or just to get around the 15 minute workflow run cap on the official spindle.

It’s very important that you keep in mind that workflow runners execute code and commands on your machine. Locking down a workflow runner so that you can safely run untrusted code is a very hard problem. Fortunately, the spindle is only usable by approved users, and if someone makes a PR on your repo, the workflows will not run unless explicitly approved by an owner. Additionally, any secrets set up for the repo are not injected into workflows that run on PRs from forked repos, same as how Github works.

So with that security warning done, let’s set up our spindle! Start by adding the new Caddy record.

```elixir
   spindle.example.com {
       reverse_proxy spindle:6555
   }
```

There’s no community spindle image, like there is for knot, but we can have the compose build from source. Add the new service to your existing compose, as well as the new volumes.

```elixir
  spindle:
    build:
      context: https://tangled.org/tangled.org/core.git#v1.16.0-alpha
      dockerfile: localinfra/spindle.Dockerfile
    restart: always
    environment:
      SPINDLE_SERVER_HOSTNAME: spindle.example.com
      SPINDLE_SERVER_OWNER: did:plc:YOUR_DID
      SPINDLE_SERVER_DB_PATH: /data/spindle.db
      SPINDLE_SERVER_LOG_DIR: /var/log/spindle
    volumes:
      - spindle_data:/data
      - spindle_logs:/var/log/spindle
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  spindle_data:
  spindle_logs:
```

The nixery engine needs access to the Docker socket to start the containers that run the workflows. Start your combined compose.

```bash
docker compose up -d
```

Alright, now we go through the same process again. Log in to Tangled, go to your Settings, find the Spindle section, and register your spindle. Once verified, you can go to any repo you own and add that spindle to it in the repo settings. Here’s a test workflow to prove that it works, create it in `.tangled/workflows/hello.yml`.

```bash
when:
  - event: ["push", "manual"]
    branch: ["main"]
engine: "nixery"
steps:
  - name: "hello"
    command: echo "running on my own spindle"
```

There it is. A workflow on a self-hosted knot running on a self-hosted spindle. Magic!

## Improvements

Knots also support a hardened security mode, although the instructions don't cover docker. The reason you might want to care about this is the know will execute `git` commands, and so any `git` vulnerability also becomes a *you* vulnerability. Since the knot is members only, that limits the surface area to who you add as members, but it’s good to be aware of.

For the spindle I can’t really cover the configuration surface area, it’s massive. You’ve got two different workflow engines: `nixery` and `microvm`. `microvm` can be seen as an improvement on the older engine, but requires access to `/dev/kvm` which is often not available on VPSs. You can pass an incredible number of different env vars to tweak its behavior and what it can do. I’d recommend you limit who has access and experiment until you’re comfortable it’s behaving the way you expect, because a misbehaving workflow runner can disrupt your server in any number of ways.

The docs have lots of [examples of workflow definitions,](https://docs.tangled.org/spindles#spindles) for inspiration, or why not take a look at my previous blog post on how to run a [standard Elixir Phoenix workflow](https://jola.dev/posts/ci-workflows-on-tangled) on Tangled.

And as always, make sure to set up backups! You'll want to set that up for all of the volumes here to avoid risking losing data. Tangled mirror your knots, but don't rely on that, have backups!

## Conclusion

I hope you’re enjoying reading this series as much as I am writing it. There’s a magic to being able to self-host things but still being able to collaborate and interact with others. Next up I’m planning to write about [atcr.io](http://atcr.io) and how to self-host [holds](https://atcr.io/learn-more).
