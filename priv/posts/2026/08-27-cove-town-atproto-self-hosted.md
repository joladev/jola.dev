%{
  title: "cove.town, atproto self-hosted self-hosting",
  author: "Johanna Larsson",
  tags: ~w(atproto self-hosting hold container registry),
  description: "How to get the atcr.io hold component up and running for atproto container registry fun."
}
---

A while ago I shared [cove.town](http://cove.town) as an experiment with atproto self-hosting. It’s driven by a docker compose and contains a [PDS](https://jola.dev/posts/self-hosting-your-pds), [a knot, a spindle](https://jola.dev/posts/self-hosting-and-tangled) and a [hold](https://jola.dev/posts/self-hosting-atproto-container-registry). The PDS owns the accounts, the knot owns the repo itself, the spindle builds the images it runs on, and the hold is the docker registry the composes point at. It’s a tiny little almost self-sufficient atproto ecosystem.

I’ve now shared write ups for how to get all these components set up, step by step, so I thought I’d do one final post tying it all together.

## Building the images

The composes run on my Dokploy server, and each one points at a Docker image built on the spindle. I would love to use the newer `microvm` [engine](https://docs.tangled.org/spindles#microvm-engine), but like most hosting providers, [Hetzner](https://hetzner.cloud/?ref=SjrsM8GhyYOl) (no reason not to grab €20 off) does not provide access to `/dev/kvm`, which seems like a precondition for using `microvm` if you don’t want your workflows to take *forever*. Instead I’m using the original `nixery` engine and I’m cheekily giving the workflow access to the docker socket. Is this a good idea? Probably not, but I’ll lean on the access controls for the spindle and the fact that non-members creating a PR does not run any workflows.

So let’s take a look at one. They’re all very similar so it doesn’t matter much which one. [Here’s the PDS](https://tangled.org/cove.town/cove.town/blob/main/.tangled/workflows/pds.yml):

```bash
when:
  - event: ["push"]
    branch: ["main"]
    paths:
      - ".tangled/workflows/pds.yml"

engine: nixery

environment:
  VERSION: bc751b0ee2fef8dfebb5c36775b5aa672e5d086d

dependencies:
  nixpkgs:
    - docker-client
    - curl

steps:
  - name: build and push
    command: |
      set -euo pipefail
      echo "$CI_BOT_PASSWORD" | docker login atcr.io -u cove.town --password-stdin
      git clone https://tangled.org/tranquil.farm/tranquil-pds.git /tmp/src
      git -C /tmp/src checkout "$VERSION"
      docker build \
        --build-arg "DISTROLESS_IMAGE=gcr.io/distroless/cc-debian13:latest@sha256:a017e74bd2a12d98342dbecd33d121d2b160415ed777573dc1808969e989d94d" \
        -t "atcr.io/cove.town/tranquil-pds:$VERSION" \
        -t "atcr.io/cove.town/tranquil-pds:latest" \
        /tmp/src
      docker push "atcr.io/cove.town/tranquil-pds:$VERSION"
      docker push "atcr.io/cove.town/tranquil-pds:latest"

  - name: trigger redeploy
    command: |
      curl -fsS -X POST "$DOKPLOY_WEBHOOK_PDS"

```

So working my way through it, the `when` section specifies pushes to main only, and filters on the file changing. This means I only build new images when I change the workflow, or, more importantly, when I bump the version in the file, to match a new tranquil-pds release.

The dependencies we need are minimal, `docker-client` for building the container images, and `curl` to hit the webhook at the end. We have to log into [atcr.io](http://atcr.io) to push, passing an app password from the repo secrets. The account that pushes the images lives on the PDS. I override the default distroless image because my server is an ARM machine.

Finally, a webhook hitting my Dokploy instance to get the compose to pull the latest image. And that’s it, the compose owned by Dokploy, everything else on atproto. Take a look at the [rest of the repo and the workflows](https://tangled.org/cove.town/cove.town). Most of the setups are more complex than the guides I’ve written, so feel free to copy and adjust.

## Thank you for reading

And that’s it! That’s the end of the series. That’s what I would be writing here, if it wasn’t for the fact that Tangled are releasing new components and I’m working on migrating. Expect a write up on migrating from knot1 to knot2 soon!

But this has been an incredibly fun and educational project, and it’s just made me want to dig deeper into the infrastructure that underpins the ATmosphere and all these incredible services built on top of it.

ps I guess the only thing I’m missing now is a self-hosted component that runs composes for me, backed by on-protocol “deployments” or “stacks”. Would be cool if deploying was just writing to my repo…
