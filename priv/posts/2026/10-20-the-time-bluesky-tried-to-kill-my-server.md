%{
  title: "The time Bluesky tried to kill my server",
  author: "Johanna Larsson",
  tags: ~w(atproto relay jetstream pds),
  description: "Some unusually shaped data enraged the Bluesky relays and they proceeded to attempt to murder my server."
}
---

Ok, now that have your attention, it was actually more like “the time that the relays running indigo-relay, a codebase maintained Bluesky, tried to kill my PDS”. Because only some of them are actually operated by Bluesky, there are lots of independent ones running the same codebase!

## The story

So I was minding my own business working on [Kite](https://tangled.org/jola.dev/kite) when I suddenly get notifications that my server on Hetzner has been sitting at >95% total CPU usage over the last 10 minutes. I go to Grafana and find this.

<div class="bleed">
  <img src="/images/postgres-network-overload.png" alt="A screenshot of a Grafana dashboard showing Postgres outgoing traffic at 1GB per second" loading="lazy" decoding="async" style="margin-bottom:30px;margin-top:16px" />
</div>

That’s my postgres instance sending 1GB/s of data internally on the private network. And I quickly spotted the receiver: tranquil PDS, my self-hosted atproto personal data server.

<div class="bleed">
  <img src="/images/pds-network-overload.png" alt="A screenshot of a Grafana dashboard showing PDS incoming traffic at 1GB per second" loading="lazy" decoding="async" style="margin-bottom:30px;margin-top:16px" />
</div>

A combination of postgres, tranquil, and traefik were pinning my 8 vCPU server to close to 100% saturation.

<div class="bleed">
  <img src="/images/server-cpu-usage-overload.png" alt="A screenshot of a Grafana dashboard showing server total CPU at close to 100% over a longer period of time" loading="lazy" decoding="async" style="margin-bottom:30px;margin-top:16px" />
</div>

My PDS dashboard gives a lot more information.

<div class="bleed">
  <img src="/images/pds-subscribe-repos-rate.png" alt="A screenshot of a Grafana dashboard showing PDS operations per second per endpoint, with subscribeRepos at the top" loading="lazy" decoding="async" style="margin-bottom:30px;margin-top:16px" />
</div>

I’m receiving a massive amount of `subscribeRepos` requests. At first I thought that it might be someone messing with my server, but digging into the logs I found that it wasn’t that at all. It was 9 different relays constantly connecting and disconnecting, requesting the same cursor backfill over and over again. Checking against some known relays I could see they were all built from indigo-relay.

So they keep pulling the same commit from the firehose, exiting, reconnecting, and then pulling that commit again. The cursor wasn’t advancing at all. I connected to my DB and looked it up and… was horrified at what I saw. Somehow I had created a 10MB atproto record!

I had so many questions… the record was created by the [shelf.cafe](http://shelf.cafe) account, so there was a bug in my code, it wasn’t supposed to do that. Followed by, how did the PDS even allow it!? Surely that’s too big!? And then the sheer panic of: what do I do now, my server is on fire.

To make a long story short, I overwrote the record using goat, which meant the record was no longer in my repo, but the firehose event is still there. I ended up doing live open heart surgery on my Tranquil DB to change the firehose event from a commit to a sync event, dropping the oversized blocks. The relays accepted it, the cursor advanced, and they picked up the new version of the record. Balance has been restored. I was later told I could’ve just deleted the event!

ps I tried to read the record through [https://pdsls.dev](https://pdsls.dev/) when it was the 10MB version and the page just hung indefinitely.

## What happened after

Incident over, I was left with all those questions. Why were the relays hammering my server? How did the PDS accept that massive write? Why is <50 `subscribeRepos` requests per second enough to saturate 8 CPUs? Why are they not getting rate limited!?

Here’s everything I’ve found.

### Murderous relays

The pattern I saw was that the relays connected, tried to read a commit, abruptly disconnected, and then tried to reconnect to read the same commit. The combination of the size of the commit and the instant reconnections by the relays led to the overload of my server. Safe to assume the relay didn’t like the commit!

Looking into the [indigo relay code](https://github.com/bluesky-social/indigo/tree/3beb6e491b793834f6c66aed9963a255f56f1b6b/cmd/relay) I found a few things worth noting here. First of all, the error I hit on: indigo has a [5MB message size limit](https://github.com/bluesky-social/indigo/blob/main/cmd/relay/stream/consumer.go#L18) set that [explicitly drops any connections that send a larger message](https://github.com/bluesky-social/indigo/blob/main/cmd/relay/stream/consumer.go#L149-L150). 

```go
const MaxMessageBytes = 5_000_000

...

	// global maximum WebSocket message size; connection will drop if exceeded
	con.SetReadLimit(MaxMessageBytes)

```

I was sending a 10MB commit across the connection, so the consumer was dropping the connection. But why no backoff? [This line tells quite a story.](https://github.com/bluesky-social/indigo/blob/3beb6e491b793834f6c66aed9963a255f56f1b6b/cmd/relay/relay/slurper.go#L357)

```go
			// TODO: measure the last N connection error times and if they're coming too fast reconnect slower or don't reconnect and wait for requestCrawl
			logger.Warn("host connection failed", "err", err, "backoff", backoff)
```

It has backoff for failures to connect to the server, but not for the connection dropping after.

A few takeaways here, the first one is that the relay would behave better if it did implement backoff for these errors ([issue reported here](https://github.com/bluesky-social/indigo/issues/1514)). But the second one is that if they did, I wouldn’t have spotted the issue as easily as this. It’s likely my alerts wouldn’t have gone off. And even with backoff the consumer is stuck and can’t progress, and the rest of the network would stop seeing updates from my account.

Which brings us to the next question, how big can a record really be? Digging into the spec I see that for writing a record the spec doesn’t actually require anything specific at all, apart from a loose recommendation to avoid making records larger than 1MiB in their CBOR representation. But the relay wasn’t choking on the record, it was choking on the commit. Turns out, commits do have strict limits, and they’re *lower* than the recommended limit for records! A single commit record CBOR bytes should not surpass 1MB. Which is less than 1MiB, for [those who like me can’t remember which one is which](https://northsky.app/profile/jola.dev/post/3my553en5pk2t). Additionally, the combined size of the records in a commit should not be higher than 2MB.

So what does indigo-relay do with commits that have a blocks content larger than 2MB? Not what you’d expect! If the size is specifically between 2MB and 2MiB, [it silently drops the commit and progresses the cursor](https://github.com/bluesky-social/indigo/blob/main/cmd/relay/relay/verify.go#L23-L42). If [it’s larger than 2MiB, it rejects the commit](https://github.com/bluesky-social/indigo/blob/main/api/atproto/cbor_gen.go#L839-L849). Which also kills the connection. And immediately restarts with no backoff. Well, you know the rest.

_Yes, this means that creating a >2MiB (CBOR representation) record on any un-upgraded Tranquil instance will enrage the relay gods and they will bring hellfire down upon the server._

### Betrayed by my own PDS

Which brings us to the question of how I ended up with a 10MB record on my PDS. The first part was just a bug in [shelf.cafe](http://shelf.cafe) that failed to truncate some text. Boring, let’s move on. The second part is more interesting, the tranquil part.

Because in fact Tranquil doesn’t impose any limits at all on record size. Which is reasonable, right? The spec doesn’t actually require anything at all on *that side* of things. This means you could make a 1GB record if you wanted to. I wouldn’t recommend it though, for the obvious reasons.

The spec does have strict opinions on commit sizes though, 1MB bytes worth of blocks per record, and 2MB total. Tranquil enforces neither. It does catch the separate spec requirement of a maximum of 200 operations on a batch! But to summarize, Tranquil doesn’t validate the record size or the combined record size, in the commit. Rather it didn’t: since v0.7.0 Tranquil now validates both! Here’s the [PR that introduced validation when writing large records](https://tangled.org/tranquil.farm/tranquil-pds/pulls/315), and [here’s the one that validates large commits](https://tangled.org/tranquil.farm/tranquil-pds/pulls/316).

This is a very good reason to upgrade to v0.7.0.

### The cost of `subscribeRepos`

So now we’ve gotten to the topic of why 40 RPS of `subscribeRepos` was enough to overload my server. It’s interesting because you’d think it’s just setting up the connection and then loading the first commit after the cursor. Admittedly with a 10MB commit that’s not cheap, but there’s a few reason why this turns out to be more expensive than it needs to be.

On the initial HTTP request with upgrade headers, Tranquil starts doing a lot of work before the websocket is even established. This includes fetching the oldest commit from after the cursor sent in the request, in order to grab the oldest `created_at`. It fetches the whole commit, which in my case was 10MB, just to get the 8 byte `created_at`. And then it starts prepping up to 1000 commits, fetching them all from DB (including my 10MB record a second time) and doing all the work of encoding the websocket CAR/CBOR websocket frames. Turns out, all this work kinda happens even if there’s nobody listening on the other side.

Then Tranquil starts sending the commits one by one. As we know, in my case the relay disconnected right after the first commit. That’s a lot of unnecessary work done. I did sneak in a quick fix which would significantly mitigate the data loaded in my extreme scenario, [Tranquil now only reads the](https://tangled.org/tranquil.farm/tranquil-pds/pulls/314) `created_at` column on the commit when looking up the oldest commit from after the cursor.

Even with that fix, this is an expensive endpoint. In fact, even without massive commits you can easily peg the CPU at 100% for Tranquil PDS server with a command like:

```bash
wrk -t4 -c100 -d300s \
     -H 'Connection: Upgrade' \
     -H 'Upgrade: websocket' \
     -H 'Sec-WebSocket-Version: 13' \
     -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
     'https://pds.cove.town/xrpc/com.atproto.sync.subscribeRepos?cursor=0'
```

The headers are not magic, they’re just dummy values required by the WebSocket specification. This is again a very good reason to upgrade to Tranquil 0.7.0, because next up we get to the biggest mitigation.

### The lack of limits rated

Which brings us to the final piece. Tranquil had rate limits across most endpoints, but not `subscribeRepos`. This is critically an expensive operation compared to something like `getRecord`. The lack of rate limits has also been addressed in Tranquil PDS 0.7.0, it’s now limited to one request per minute with a burst of five, matching how much it costs us to execute this operation. This should be plenty for everyday operation, and worst case a relay would have to wait for a minute before reconnecting. They have backoff on failures on the initial request, it’s just missing in this scenario where the connection dies and returns an error.

## Takeaways

That was quite a ride! From me getting paged by my server overloading to releasing Tranquil PDS 0.7.0, and in the process I learned so much about atproto and Sync 1.1. I understand conceptually that atproto records and the sync spec are separate things, and don’t by definition have to have matching limits set, but in practice I think most users would expect that if they’re able to create a record, that that record can also be propagated through relays. 

Although all of this went back to me having made a mistake that led to the unusually large record, it did expose some rough edges in the protocol. Again, imagine if the relay had backoff implemented here, my server would not have alerted to me to a problem. In that scenario, nine major relays would get stuck and be unable to move forward on ingesting any events from my PDS. Me and everyone else on the server would just experience it as super weird consistency bugs where data exists in one place and not in another, across the protocol, until I dig deep enough into the telemetry to discover the problem.

That doesn’t feel like the ideal design. It would be cool if there was some more proactive process, alerting you that a relay is unable to ingest your firehose. Anyway, not sure what that should look like. Maybe it’s just the responsibility of the PDS to put that information front and center.

The upside of all of this is that Tranquil got a bunch of nice fixes that should prevent this from *befalling* anyone else!
