%{
  title: "Tangled in a box",
  author: "Johanna Larsson",
  tags: ~w(atproto tangled git),
  description: "What if you could run your own Tangled on a private network, behind Tailscale, or locally."
}
---

This was the result of a question I saw on Lobste.rs, on whether it was possible to run a copy of Tangled that could only be accessed through a Tailscale private network and not exposed to the public internet. I responded that yeah, theoretically, you'd just need to set up all of the components with a custom PDS and PLC, for your own private identities that don't leak out. This is actually similar to what people tend to set up to do atproto development, and the setup I use when working on [shelf.cafe](https://shelf.cafe) locally.

So then I thought, why not...

## Introducing Tangled in a box

Tangled in a box is a proof of concept of the Tangled stack, packaged for running locally or in a private environment, not connected to the public internet. Please don't expect this to be a battle-hardened and polished product, it's just a bit of fun. But it works!

To get set up, clone [https://tangled.org/jola.dev/tangledinabox](https://tangled.org/jola.dev/tangledinabox) and run:

```bash
docker compose up -d
./trust.sh
```

This will pull down the pre-built images and start everything up, as well as running a little bootstrap script that creates a user called `dolly.tangled.inabox.at` with the password `Lewis-Stan1`. As soon as it's started, go to [https://tangled.inabox.at](https://tangled.inabox.at) and log in. There you go! The authenticated landing page is a bit lackluster since it's pretty focused on the social collaboration and this is... not that. But it works. Next, go to settings and add your SSH key, then go create a repo. You should be able to push, and it should just be reflected in the frontend. Neat.

## Notes

You can see which revisions are used for each project in the compose. I originally wanted to use more tags, but a lot of the tags are no actually usable, for example the Tangled v1.20.0 knot containerfile is broken. But it should all roughly represent the v1.20.0 version.

This is not much of a codebase at all, it's just a bunch of pre-configured components and pre-built images. You could definitely take this and make it yours, modify the bootstrap script, tweak options for the components. If you're actually set on running your own private Tangled behind Tailscale or something, then you probably want to replace all my hardcoded plaintext secrets in the compose and config files. It might be a useful starting point though! For some examples of properly configured components, take a look at [cove.town](https://cove.town).

## Components

So I'm not gonna go through all the components, but here are the highlights:

### PDS

You need a PDS to deal with accounts, record storage, identity, auth, all that good stuff. As a maintainer of the excellent Tranquil PDS project, that was an obvious choice. It also happens to be what the real Tangled runs too! When you log in this is the thing that's asking you for your password. This is also where all your records get stored.

### PLC

In the "real" world, everyone relies on [https://plc.directory](https://plc.directory) for identities, and it serves the did doc that everything goes to check to see what handle that did belongs to and where their PDS is. Since we can't use the public one, we have to run our own. Fortunately all the components in this stack accept a PLC URL override, so we can point them at our local one.

### Knot

This is the git repo server. It is actually a kind of PDS too, except you don't have your account on it, your repo does! Each repo gets its own identity, which means in the future it'll be possible to migrate repos. That's nice. It's also responsible for producing all kinds of records and stuff.

### Hydrant

Hydrant is this kinda hard to describe thing, because it's so versatile and runs in different modes with different settings. For this stack, it acts as the relay, ensuring that updates from the PDS and the knot are _relayed_ to other components. I really wanna run one of these in [cove.town](https://cove.town).

### Bobbin

One of the things subscribing to updates through hydrant, bobbin is responsible for keeping a full copy of all the Tangled atproto records, and providing API access to it. For this setup that's partitioned off from the internet, it's not going to be holding much data at all. But it's still contributing! It powers the frontend.

### Frontend

The UI that you interact with Tangled through, the thing you see when you go to [https://tangled.inabox.at](https://tangled.inabox.at). Under the hood it's querying bobbin and other services to render pages.

## Next up

I love that this is possible. That I could just go and build all these components and fit them together, and it works. Anirudh Oppiliappan of Tangled talked at Git Merge about [how the git forge must be hackable](https://www.youtube.com/watch?v=qd3BxUwLFbk), and this feels exactly like it? You can take pieces, swap them out, remix, make it your own thing. Of course, I don't think he was primarily thinking about building things that _didn't_ federate. But it still counts!

Issues and PRs are perfectly welcome on [https://tangled.org/jola.dev/tangledinabox](https://tangled.org/jola.dev/tangledinabox), or if you just want to fork it and do your own thing, that's cool too.
