%{
  title: "Taking control of your atproto account",
  author: "Johanna Larsson",
  tags: ~w(atproto),
  description: "Setting a rotation key on your atproto (Bluesky, Eurosky, etc) account means you can recover it even if the account provider shuts down."
}
---

In atproto backed services, like Bluesky, your identity and all of your data lives in your repo on your PDS (Personal Data Server). If you signed up through Bluesky it's one of their servers, but there are lots of other services that offer atproto accounts, each one maintains one or more PDSs. There are community run ones, and it's not a huge lift to just run one for yourself. At the time of writing this there are more than [6,000 PDSs in different states of activity](https://pds.directory/). Each handle, like `@jola.dev`, maps to a DID (Decentralized Identifier) document that represents your identity, and contains the canonical reference to where the account data lives: your PDS server. These mappings are maintained by [plc.directory](https://plc.directory). You can see mine [here](https://plc.directory/did:plc:bvraa6gajy4tfr3eh2sisdkr).

Atproto is designed around the idea that you own your own identity and data, so it would be a big problem if the maintainer of your PDS could suddenly decide to delete your account or shut down the server, leaving you without access to your identity. The solution to this is [rotation keys](https://atproto.com/guides/account-recovery), and the concept of [adversarial migration](https://www.da.vidbuchanan.co.uk/blog/adversarial-pds-migration.html). As the Bluesky docs state, you don't _have to_ do this. It's not unreasonable to trust Bluesky with your handle. But it's a lot more fun take control of your account! Note that rotation keys don't solve the problems of the data itself, for that you'll want to create backups.

## Setting your own rotation key

I just went through the process of adding rotation keys so I wanted to write up the process. Overall it's very quick and straightforward. You're going to want a few things before you start:

1. A password manager or other safe place to store your private key.
2. Install the command line tool [goat](https://github.com/bluesky-social/goat), for example with `brew install goat`.
3. Run `goat key generate` and record the two values it prints. The public one looks like `did:key:<text>`, you're going to record this in your DID document. The private one is a random set of characters, store this in a safe place.

Okay, with that out of the way.

```bash
goat account login -u <HANDLE> -p <PASSWORD>
```

Ensure the password is the password you log in with, not an "app password". If you have 2FA enabled, you're going to get an error saying to check your email. Get the token and rerun the command with `--auth-factor-token <TOKEN>`.

To verify that it worked, run a command to get your PLC document.

```bash
goat account plc current
```

For me that outputs this.

```json
{
  "did": "did:plc:bvraa6gajy4tfr3eh2sisdkr",
  "verificationMethods": {
    "atproto": "did:key:zQ3shmuZAiJ7LF1spHm2hNHwEmrQ9yKcXTo6XtsV8ii7YZYq7"
  },
  "rotationKeys": [
    "did:key:zDnaebJGrFiPqR21GSMRHy4huHxSdSPVozZcsxzbX9NrCoSoj",
    "did:key:zQ3shhCGUqDKjStzuDxPkTxN6ujddP4RkEKJJouJGRRkaLGbg",
    "did:key:zQ3shpKnbdPx3g3CmPf5cRVTPe1HtSwVn5ish3wSnDPQCbLJK"
  ],
  "alsoKnownAs": [
    "at://jola.dev"
  ],
  "services": {
    "atproto_pds": {
      "type": "AtprotoPersonalDataServer",
      "endpoint": "https://shaggymane.us-west.host.bsky.network"
    }
  }
}
```

As you can see it references my PDS and my handle. You can also see a list of `rotationKeys`. The top one is the one I added myself through this process, the two others belong to Bluesky.

Okay, time to request a token to use to modify the PLC record.

```bash
goat account plc request-token
```

You'll get an email from your PDS, eg Bluesky, with a token. Grab it and paste it into the next command.

```bash
goat account plc add-rotation-key --first --token <TOKEN> <PUBLIC_KEY>
```

The public key is the one you generated earlier and should look something like `did:key:string`. Once this command completes you're done. You've now attached your own rotation key to your account. Take a look!

```bash
goat account plc current
```

You should now see your public key listed as the first key under `rotationKeys`. Success!

## Conclusion

The goal of this was to have a rotation key that you own yourself, giving you the ultimate say in what happens to your account. It's very likely that you never need to use this for anything, but it's definitely better to have it and not need it than the opposite!

To read more about PDS migrations, take a look at the excellent [https://www.da.vidbuchanan.co.uk/blog/adversarial-pds-migration.html](https://www.da.vidbuchanan.co.uk/blog/adversarial-pds-migration.html). If you're looking to migrate PDSs but want a more managed experience, take a look at [PDSMoover](https://pdsmoover.com/), or if you're migrating to Eurosky, follow their instructions [here](https://eurosky.tech/accounts/migrate/). Migrations still take some steps and could be a smoother experience, but armed with your rotation key you can feel safe that your identity doesn't end up stuck on some unmaintained PDS.
