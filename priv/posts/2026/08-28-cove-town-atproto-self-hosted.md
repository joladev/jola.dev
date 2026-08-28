%{
  title: "cove.town, atproto self-hosted self-hosting",
  author: "Johanna Larsson",
  tags: ~w(atproto self-hosting hold pds spindle knot container registry),
  description: "cove.town consists of a PDS, a knot, a spindle, and a hold, and is fully built on itself. The source code is hosted on the knot, updates trigger workflows running on the spindle that build container images hosted on the hold, and the accounts that own the services live on the PDS."
}
---

A while ago I shared [cove.town](http://cove.town) as an experiment with atproto self-hosting. It’s driven by a bunch of little docker composes and contains a [PDS](https://jola.dev/posts/self-hosting-your-pds), [a knot, a spindle](https://jola.dev/posts/self-hosting-and-tangled) and a [hold](https://jola.dev/posts/self-hosting-atproto-container-registry). The PDS owns the accounts, the knot owns the repo itself, the spindle builds the images it runs on, and the hold is the docker registry the composes point at. It’s a tiny little almost self-sufficient atproto ecosystem.

I’ve now shared write ups for how to get all these components set up, step by step, so I thought I’d do one final post tying it all together.

## Building the images

The composes run on my Dokploy server, and each one points at a Docker image built on the spindle. I would love to use the newer `microvm` [engine](https://docs.tangled.org/spindles#microvm-engine), but like most hosting providers, [Hetzner](https://hetzner.cloud/?ref=SjrsM8GhyYOl) (referral link for €20 off) does not provide access to `/dev/kvm`, which seems like a precondition for using `microvm` if you don’t want your workflows to take *forever* using qemu emulation. Instead I’m using the original `nixery` engine and I’m ~cheekily giving the workflow access to the docker socket~ I'm using `kaniko` to build the images without a docker socket! Anyway, we also have access controls for the spindle and the fact that non-members creating a PR does not run any workflows.

So let’s take a look at one. They’re all very similar so it doesn’t matter much which one. [Here’s the PDS](https://tangled.org/cove.town/cove.town/blob/main/.tangled/workflows/pds.yml):

```yaml
when:
  - event: ["push"]
    branch: ["main"]
    paths:
      - ".tangled/workflows/pds.yml"

engine: nixery

environment:
  VERSION: bc751b0ee2fef8dfebb5c36775b5aa672e5d086d
  KANIKO_IMAGE: ghcr.io/osscontainertools/kaniko:v1.28.3@sha256:779f463aaa3219151ceff518249aa043a60bcb09a17fab58b915f63c678ecde6

dependencies:
  nixpkgs:
    - go-containerregistry
    - gnutar
  github:nixos/nixpkgs:
    - bash
    - curl
    - cacert

steps:
  - name: build and push
    command: |
      set -euo pipefail
      crane export --platform linux/arm64 "$KANIKO_IMAGE" - | tar -xf - -C /tmp kaniko/executor
      export DOCKER_CONFIG=/tmp/docker-config
      mkdir -p "$DOCKER_CONFIG"
      echo "$CI_BOT_PASSWORD" | /tmp/kaniko/executor login atcr.io -u cove.town --password-stdin
      git clone https://tangled.org/tranquil.farm/tranquil-pds.git /tmp/src
      git -C /tmp/src checkout "$VERSION"
      /tmp/kaniko/executor \
        --context /tmp/src \
        --ignore-path /tmp/src \
        --ignore-path /tmp/docker-config \
        --ignore-path /tangled \
        --ignore-path /nix \
        --build-arg "DISTROLESS_IMAGE=gcr.io/distroless/cc-debian13:latest@sha256:a017e74bd2a12d98342dbecd33d121d2b160415ed777573dc1808969e989d94d" \
        --destination "atcr.io/cove.town/tranquil-pds:$VERSION" \
        --destination "atcr.io/cove.town/tranquil-pds:latest"

  - name: trigger redeploy
    environment:
      SSL_CERT_FILE: /tangled/home/.nix-profile/etc/ssl/certs/ca-bundle.crt
    command: |
      curl -fsS -X POST "$DOKPLOY_WEBHOOK_PDS"
```

So working my way through it, the `when` section specifies pushes to main only, and filters on the file changing. This means I only build new images when I change the workflow, or, more importantly, when I bump the version in the file, to match a new tranquil-pds release.

It defines a few dependencies that the nixery server provides for us. I'm [self-hosting the server](https://tangled.org/cove.town/cove.town/blob/main/nixery/docker-compose.yml) because of reliability issues with the Tangled one. [Nixery](https://github.com/tazjin/nixery) is this magic tool that builds container images on demand, so that's how we get the environment set up.

Next, we're using [kaniko](https://github.com/osscontainertools/kaniko) to build the docker image in user space, no socket required, while sidestepping the problem with not having `/dev/kvm` and not being able to use `microvm`. The version of Kaniko we want is only distributed as a container image, so I use `crane` to unpack it. Note that Kaniko wipes the local disk when it runs, but you can protect directories you want to keep around with `--ignore-path`.

Once built, we have to log into [atcr.io](http://atcr.io) to push, passing an app password from the repo secrets. The account that pushes the images lives on the PDS. I override the default distroless image because my server is an ARM machine. 

Finally, a webhook hitting my Dokploy instance to get the compose to pull the latest image. And that’s it, the compose owned by Dokploy, everything else on atproto. Take a look at the [rest of the repo and the workflows](https://tangled.org/cove.town/cove.town). Most of the setups are more complex than the guides I’ve written, so feel free to copy and adjust.

## Thank you for reading

And that’s it! That’s the end of the series. This has been an incredibly fun and educational project, and it’s just made me want to dig deeper into the infrastructure that underpins the ATmosphere and all these incredible services built on top of it.

ps I guess the only thing I’m missing now is a self-hosted component that runs composes for me, backed by on-protocol “deployments” or “stacks”. Would be cool if deploying was just writing to my repo…
