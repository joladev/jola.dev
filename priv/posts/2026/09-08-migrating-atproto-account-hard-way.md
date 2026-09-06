%{
  title: "Migrating your Bluesky account the hard way",
  author: "Johanna Larsson",
  tags: ~w(atproto pds),
  description: "I used the goat command line tool to migrate my main Bluesky account to a new server and survived to tell the tale."
}
---

When I set up my main Bluesky account, [@jola.dev](https://bsky.app/profile/jola.dev), I signed up through Bluesky. This means my account and my data lived on one of the very many Bluesky Personal Data Servers (PDS). Specifically, mine was created on [shaggymane.us-west.host.bsky.network](https://shaggymane.us-west.host.bsky.network/). This blog post isn’t about how atproto works under the hood, but the relevant bit is that when you post on Bluesky that post is stored on your PDS. It’s also stored in the Bluesky AppView, and replicated across the protocol for anyone who’s interested, but the source of truth is your PDS.

The way it’s designed, your PDS doesn’t have to be Bluesky infrastructure for you to be able to post on Bluesky. It’s a decentralized design and you can run your own server. So obviously you should! The other day my specific PDS was down for a couple of hours, and I kept thinking about how cool it would be if it was _my own_ fault my PDS was down instead of someone else's.

I’ve previously written about [cove.town](http://cove.town) and [setting up a PDS](https://jola.dev/posts/self-hosting-your-pds), and I’ve wanted to move my main account to it, but I have been dragging my feet. A big part of why was just a lack of confidence in the migration process itself. Turns out that was unfounded! Ps you should [set a rotation key on your account if you haven't](https://jola.dev/posts/taking-control-atproto-account), it's just a good idea.

## How to prepare for migration

[@bnewbold.net](https://bsky.app/profile/bnewbold.net) wrote a [guide for how to migrate your account](https://whtwnd.com/bnewbold.net/3l5ii332pf32u) using the [goat](https://github.com/bluesky-social/goat) command line tool last year, and the instructions have withstood the test of time.

The instructions here mostly match that guide, with just a few added notes from my own experience. Also before I continue, note that there are managed services like [PDS Moover](https://pdsmoover.com/) that you can use to migrate instead of the command line tool, if you prefer a more browser based experience.

Before you embark on this journey, you need a new PDS to go to. Some of them have open registration, otherwise you’ll need an invite code. Write it down somewhere, you’ll need it for the migration proper.

So, first of all, make sure you’ve got `goat` installed.

```bash
brew install goat
```

Let’s confirm it’s working by logging in. Note that you must use your account password, not an *app password*.

```bash
# adding a space before the command prevents it from being stored
# in history, you don't want your password in there.
 goat account login -U <username> --password <password>
```

If you’ve got 2FA set up, you’ll get an error telling you you need a code. If you’re on Bluesky, this code will arrive by email. Take the code run the same command again

```bash
 goat account login -U <username> --password <password> --auth-factor-token <token>
```

Okay, following that success, we can confirm we’re logged in.

```bash
goat account check-auth

# should output something like
DID: <yourdid>
Host: <your pds>
{
  "activated": true,
  ...
}
```

Perfect. So before we continue, let’s do a backup of the account. Go to a folder of your choosing, this is just for backing up purposes. If you don’t care you can skip this step.

```bash
goat repo export <yourdid>
goat blob export <yourdid>
```

You should now have a file in your current folder called something like `did/plc/yourdid.20260821211639.car` , that’s your cryptographically signed repo, basically all your content. And there should be a folder called something like `did/plc/bvraa6gajy4tfr3eh2sisdkr_blobs` with all your blobs in it. Running `repo export` again creates a new `.car`. Running `blob export` again pulls down any *new* blobs, avoiding downloading existing ones again.

## How to migrate your account

That’s it. You can rerun the export step as many times as you want. The stuff it pulls down is just your local backup, but we’re not going to need it for the migration itself.

Once you’re ready, request a PLC token since this requires committing a PLC operation (repointing your account to a new PDS).

```bash
goat account plc request-token
```

This should result in another email, this time containing your PLC token. Ok, we’re ready to go with the migration command itself. This is a one single command process. It’ll work for a while and then you’re done. You need to make sure you have all the stuff we’ve gone through: an invitation code if required, a PLC token, an email address, a password, the account handle, and the host URL for the PDS you’re moving to.

```bash
goat account migrate \
    --pds-host $PDS_HOST \
    --new-handle $HANDLE \
    --new-password $PASSWORD \
    --new-email $EMAIL \
    --plc-token $PLC_TOKEN \
    --invite-code $INVITATION_CODE
```

Fill in all the values above and run the command. As before, if you’re putting passwords and stuff in your terminal you can add a space before `goat` to avoid saving it to history. My output from running the command looked like this:

```bash
026/09/06 13:55:38 INFO new host serviceDID=did:web:pds.cove.town url=https://pds.cove.town
2026/09/06 13:55:38 INFO creating account on new host handle=jola.dev host=https://pds.cove.town
2026/09/06 13:55:40 INFO migrating repo
2026/09/06 13:55:43 INFO migrating preferences
2026/09/06 13:55:43 INFO migrating blobs
2026/09/06 13:55:44 INFO transferred blob cid=bafkreia2z3vrt3bre265muoagkxixfy73lgagoztgccrsloe7t5y3jvmgu size=64334
2026/09/06 13:55:45 INFO transferred blob cid=bafkreia3arzdrm6fhxik6mffl3cjur3zizclrostpwgqczuv6qevezimji size=714472
...
2026/09/06 13:56:51 INFO account migration status status="&{Activated:false ExpectedBlobs:191 ImportedBlobs:189 IndexedRecords:1768 PrivateStateValues:0 RepoBlocks:2234 RepoCommit:bafyreibh5af3uzkqh3cwsziwallu6wydjqzhlc3l67htct2t72xhx3lrwq RepoRev:3muu24imyax22 ValidDid:false}"
2026/09/06 13:56:51 INFO updating identity to new host
```

Ignore the mismatch in `ExpectedBlobs` and `ImportedBlobs`, that turned out to just be a little quirk in Tranquil PDS that I’m putting up a PR for. 

Confirm your identity is now resolving to the new PDS host.

```bash
curl -s "https://plc.directory/<yourdid>" | jq .service.0.
```

That should return your new PDS host. You did it! And so did I, [@jola.dev](https://bsky.app/profile/jola.dev) is on [cove.town](http://cove.town) now!

## Wrapping up

You might get a little blip as some services cache identity lookups, the cleanest way to deal with that is to log out of everything and log back in. Bluesky will offer to “reactivate” your account if you’re still logged in, **do not do this**. Click cancel and you get logged out. Log in again and you’re good!

That’s it. Now you get to enjoy being smug about your account not being down when Bluesky has an outage. Well, you can’t tell anyone cause Bluesky is having an outage, but once it’s back up, you can be *so smug*.
