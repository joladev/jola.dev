%{
  title: "Migrating to the new Tangled knot2",
  author: "Johanna Larsson",
  tags: ~w(atproto self-hosting tangled knot),
  description: "Tangled is a Github alternative built on atproto. I've previously shown you how to set up the self-hosted repo server, here I go through migrating to knot2."
}
---

Tangled are in the process of migrating to the new knot implementation, knot2. As a quick reminder, the knot is a self-hostable server capable of serving git repos that uses atproto to share information with the ATmosphere, and the Tangled AppView. This means you can self-host your own repo, like gitea or forgejo, while still being able to interact with other people in a single place.

I recently wrote about setting up [knot and spindle](https://jola.dev/posts/self-hosting-and-tangled). I had gotten everything working a week earlier, but it was while I was writing the blog post that I found out about [knot2](https://tangled.org/tangled.org/core/tree/master/knot2). Oh, well, migrating can’t be too bad, right? And there’s actually a [great guide already written up](https://docs.tangled.org/knot-self-hosting-guide#migrating-to-knot-2), as well as tooling to help you. This write up provides a more Docker focused version of the migration guide, with my personal experience.

## Prep

Okay, I hit the first challenge right off the bat. The Containerfile provided by the Tangled repo pins an `amd64` arch runner image that I can’t use, so I stripped that out to clone and build the image locally. The docker image contains the migration script, so that’s why I’m building it locally first.

```bash
git clone --depth 1 https://tangled.org/tangled.org/core /tmp/tangled-core
sed -i 's|gcr.io/distroless/cc-debian13:latest@sha256:[a-f0-9]*|gcr.io/distroless/cc-debian13:latest|' /tmp/tangled-core/knot2/Containerfile
docker build -f /tmp/tangled-core/knot2/Containerfile -t knot2:local /tmp/tangled-core
docker image inspect knot2:local --format '{{.Os}}/{{.Architecture}}'
```

And we have to create the `KNOT_MASTER_KEY`. Run this and store the value in a password manager.

```bash
openssl rand -base64 32
```

Okay, and the final little bit of setup before we do the dry-run.

```bash
printf 'KNOT_SERVER_HOSTNAME=knot.example.com\nKNOT_REPO_SCAN_PATH=/old-repos\n' > knot-migrate.env && chmod 600 knot-migrate.env
```

You need to have the `KNOT_MASTER_KEY` in the shell, so export it, and then run.

```bash
sudo -E docker run --rm --user 0:0 \
  -v "$PWD/server:/old-db" \
  -v "$PWD/repositories:/old-repos" \
  -v "$PWD/keys:/old-keys:ro" \
  -v "$PWD/knot-migrate.env:/old.env:ro" \
  -v "$PWD/data:/target" \
  -e KNOT_MASTER_KEY \
  --entrypoint /usr/local/bin/knot-migrate knot2:local \
  --source-db /old-db/knotserver.db \
  --env-file /old.env \
  --host-key /old-keys/ssh_host_ed25519_key \
  --plc-url https://plc.directory \
  --target /target \
  --dry-run
```

This is just a dry run. It’ll print out some information. Make sure it says everything looks good! You can run this any number of times. Here’s what my output looked like.

```bash
rehearsal: 0.0s
knot owner: did:plc:3pnunm7komgxzfwrrxdtvsvl
members to grant: 2
repos to adopt: 1
collaborator grants: 2

casbin cross-check: the acl and the tables agree

skipped repos: 0

transfer mode: copy
the filesystem checks used /var/lib/knot, since the scan path doesn't exist yet
scan path: writable
room to copy: 93.8GiB free is enough for the 3.7MiB that adoption will copy
host key algorithm: ssh-ed25519
master key: KNOT_MASTER_KEY decodes to a usable key

we left the target alone. Re-run without --dry-run to migrate.
```

This is the last step before we go into the “scary” part, so make sure you’re happy with the output!

## The migration

Okay, game day. It’s time to do this for real. Start by stopping your knot and do a backup.

```bash
docker compose stop knot
cp -a server/knotserver.db* /var/tmp/
```

And here’s the non-dry-run version of the migration command.

```bash
sudo -E docker run --rm --user 0:0 \
  -v "$PWD/server:/old-db" \
  -v "$PWD/repositories:/old-repos" \
  -v "$PWD/keys:/old-keys:ro" \
  -v "$PWD/knot-migrate.env:/old.env:ro" \
  -v "$PWD/data:/target" \
  -e KNOT_MASTER_KEY \
  --entrypoint /usr/local/bin/knot-migrate knot2:local \
  --source-db /old-db/knotserver.db \
  --env-file /old.env \
  --host-key /old-keys/ssh_host_ed25519_key \
  --plc-url https://plc.directory \
  --target /target
```

Here’s my output so you know what to look for.

```bash
adoption: 0.0s
cobs: 0.0s
knot owner: did:plc:3pnunm7komgxzfwrrxdtvsvl
members to grant: 2
repos to adopt: 1
collaborator grants: 2

casbin cross-check: the acl and the tables agree

skipped repos: 0

adopted by copy: 1 new, 0 already present, 1 sha1, 0 sha256

member grants: 2 appended, 0 already present
registrations: 1 appended, 0 already present
collaborator grants: 2 appended, 0 already present

knot key identity: did:web:knot.cove.town
host key algorithm: ssh-ed25519
host key fingerprint: SHA256:SKiHHmsnZV+E6fSl3MpvAH2mHQS6UH48XXW7NCeIMi8
config: /target/config.toml
key archive: /target/repo-signing-keys.json
```

Okay! Unlike knot1, knot2 wants a nice config file with lots of explicit and clean options.

```toml
[server]
hostname = "knot.example.com"
admins = ["did:plc:YOUR_DID"]
listen_addr = "[::]:5555"
ssh_listen_addr = "[::]:2222"
ssh_host_key_file = "/data/ssh_host_key"
appview_endpoint = "https://tangled.org"

[repo]
scan_path = "/data/repos"

[secrets]
sealed_key_file = "/data/sealed-keys"
master_key_env = "KNOT_MASTER_KEY"

[atproto]
plc_directory = "https://plc.directory"

[xrpc]
trusted_proxy_header = "x-forwarded-for"   # only if the knot sits behind a proxy

[git]
object_format = "sha1"   # knot2 defaults to sha256, which can't be pushed to GitHub mirrors
```

With most of the configuration done, the compose entry is pretty minimal. If you followed my previous guide, you can replace the previous knot service in place.

```yaml
services:
  knot:
    image: knot2:local
    pull_policy: never
    restart: always
    ports:
      - "2222:2222"    # update this to match your actual port, eg 22:2222
    environment:
      - KNOT_MASTER_KEY=${KNOT_MASTER_KEY}
    volumes:
      - ./config.toml:/etc/knot/config.toml:ro
      - ./data:/data
```

Now we’re ready to go:

```bash
docker compose up -d
```

here are some commands you can run to verify it works

```bash
curl -s https://knot.example.com/xrpc/_health          # {"version":"knot 2.0.0"}
curl -s https://knot.example.com/xrpc/sh.tangled.owner # your DID
git ls-remote ssh://git@knot.example.com:2222/did:plc:YOUR_REPO_DID
git ls-remote https://knot.example.com/did:plc:YOUR_REPO_DID
```

If something did not go as expected, you should be able to bring the old knot back by restoring the compose file and running `docker compose up -d`. We haven’t actually deleted anything, it’s all still there.

**Caveat**, I briefly had it start on me before I had properly filled in the `config.toml` file. If you see logs on startup about generating a new SSH host key, the paths in your config file don’t match your actual migrated file paths. Delete `secrets/` and `ssh/` folders in the mounted directory, fix the config file, and then start the compose again.

## Clean up

Assuming your migration has gone well, you want to delete the migrated signing keys. They were stored in plain text for the migration, so let’s clear those away.

```bash
sudo rm data/repo-signing-keys.json
```

Once you’re comfortable that the migration went well, and you’ve got backups of the new volume, you can delete any other migration leftovers: `server/` , `repositories/`, `/var/tmp`, and `/tmp/tangled-core`.

## Closing notes

Big thank you to the Tangled team and @oyster.cafe for providing great documentation and a clean migration path. The new knot looks really slick. One of the big new things is that it doesn’t actually delegate to git under the hood, it comes with a [full Rust git implementation](https://github.com/GitoxideLabs/gitoxide) instead. So, hopefully fewer CVEs 🤞
