%{
  title: "CI workflows on Tangled for Elixir",
  author: "Johanna Larsson",
  tags: ~w(atproto tangled elixir phoenix oss),
  description: "How to set up CI workflows on Tangled for Elixir, with specific Elixir and Erlang versions, and a PostgreSQL service."
}
---

Continuing down the atproto rabbit hole, I spent some time getting a CI workflow set up for [https://tangled.org/jola.dev/annot.at](https://tangled.org/jola.dev/annot.at). I couldn’t find any examples of Elixir CI workflows for Tangled so it took some experimenting, 

This uses the new `microvm` engine that was only recently released, which enables us to run a PostgreSQL service in the workflow. By default it only listens on a unix socket, so we have to set some extra configuration there for it to match the standard Phoenix scaffold setup.

```yaml
when:
  - event: ["push", "pull_request"]
    branch: ["main"]

engine: microvm
image: nixos

dependencies:
  - beam29Packages.elixir_1_20
  - beam29Packages.erlang

services:
  postgresql:
    enable: true
    enableTCPIP: true
    authentication: |
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust

steps:
  - name: setup
    command: |
      mix local.hex --force
      mix local.rebar --force
      mix deps.get
  - name: compile
    command: mix compile --warnings-as-errors
  - name: format
    command: mix format --check-formatted
  - name: credo
    command: mix credo --strict
  - name: test
    command: mix test --warnings-as-errors
  - name: unused
    command: mix deps.unlock --check-unused
```

The trickiest part was using specific versions of Elixir and Erlang. You can use

```yaml
dependencies:
  - elixir
  - erlang
```

but that gives you an unspecified version of Elixir. It happened to be 1.18 when I tried. Instead, you'll want to find specific NixOS packages to depend on, like the full workflow does.

```yaml
dependencies:
  - beam29Packages.elixir_1_20
  - beam29Packages.erlang
```

The BEAM 29 packages I found here https://mynixos.com/nixpkgs/packages/beam29Packages.

I don’t have much experience with NixOS so it was a bit of trial and error to get here, but once I got the config right it runs perfect. Here’s an example run [https://tangled.org/jola.dev/annot.at/pipelines/28076/workflow/ci.yml](https://tangled.org/jola.dev/annot.at/pipelines/28076/workflow/ci.yml).

Now to go figure out how to self-host a knot and a spindle. Don’t have to do that, you can use the servers Tangled run, but it’s more fun this way.
