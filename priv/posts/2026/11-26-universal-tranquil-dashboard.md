%{
  title: "A universal Tranquil PDS dashboard",
  author: "Johanna Larsson",
  tags: ~w(tranquil gleam pds atproto),
  description: "Homestead is a standalone Tranquil PDS account dashboard that lets you log into any Tranquil instance."
}
---

[Homestead](https://homestead.at/) is a prototype of a universal Tranquil PDS account dashboard. Log in using any Tranquil-hosted atproto account and manage it in a single place, no matter what host you’re on. It also comes with a bunch of little extra features, like a place to see all your account labels, every backlink to you and your records, and lots more.

**If you have a Tranquil hosted account, on any PDS instance, you can use it to log in at [https://homestead.at](https://homestead.at)**. You can also grab the source code [here](https://tangled.org/jola.dev/homestead) and run your own. If you have accounts on multiple Tranquil PDSs, you can manage them all in one place.

This is a pure frontend application. There is no backend and no tracking. Your sessions live in your browser only.

## How did we get here?

It was while working on the big [Tranquil PDS atproto scopes rewrite](https://jola.dev/posts/tranquil-scopes-proposal) that it first really dawned on me that the Tranquil account dashboard is just a plain public OAuth application. It comes packaged with Tranquil, but it has no special accesses or handling. It’s just a regular client. The Bluesky reference PDS doesn’t do this, it uses a separate session system for the dashboard.

At first blush, it seems a bit weird not to make a sensitive account dashboard a special case. Tranquil exposes management endpoints like changing a password to OAuth sessions. It protects these endpoints with atproto scopes, previously a blanket (non-standard) `account:*?action=manage`, and more recently with specific (non-standard) attributes like `account:password?action=manage`. It’s just OAuth. That may not be ultimately very intuitive for end users.

But… it actually opens incredible doors…

## The hackable PDS

This may actually be a killer feature. If the built-in dashboard is not a special case, then anyone can make a dashboard. Anything can be a dashboard. There’s literally nothing stopping you from right now creating a Tranquil admin dashboard TUI and distributing it to other people. You can create 20 different Tranquil dashboards and log into whichever one strikes your fancy this day. Want a dashboard built in Gleam one day and one built in C another?

You can run a Tranquil instance with no attached frontend at all. When you want to log in and manage your account, do it from a CLI, or start a frontend on [localhost](http://localhost) and log in to the instance on your VPS. Set up an MCP and let your agent be your dashboard.

Build and experiment and remix your ideal account dashboard. The sky is your limit.

## What is Homestead?

As a proof of concept, I built a standalone third party Tranquil PDS dashboard. Homestead is written in Gleam and compiles to JS. The public instance at [homestead.at](http://homestead.at) uses the provided Dockerfile with Caddy to just distribute that JS bundle. All the magic happens in your browser. Sessions live fully in your browser.

You can add any number of accounts from any number of Tranquil compatible servers. It supports (almost) all account dashboard actions, and comes with a bunch of polish, including:

- Labels, see all labels attached to your account
- Backlinks, every single record that references you
- A flashier record browser, inspired by [pds.ls](http://pds.ls)
- Handle verification, check that your handle is resolving correctly
- Account and media export

There’s probably more stuff I’m forgetting. I’ve also put some effort into making the UI feel a bit more polished, and the interaction patterns intuitive. Although I wouldn’t claim the code is very idiomatic Gleam, I’m not exactly an expert.

## The stuff that has to be on the PDS

There are a few things that don’t actually belong in the OAuth client though, and so have to stay attached to the PDS instance itself. The first thing is passkeys. Passkeys are bound to the host they’re created on, so you can’t create a passkey through [homestead.at](http://homestead.at) and have it work for pds.example.com. We could potentially build a redirect flow into Tranquil to handle this, but for now Homestead directs you to your own instance to create passkeys.

The other big thing is the OAuth consent screen itself. Obviously the OAuth client can’t also be the provider of the OAuth consent screen, that actually belongs to the AS. Tranquil’s codebase blurs this a bit by having both things live together in the same project, but they are actually distinct surfaces.

The gray area is signup and login. It is actually possible to sign up through Homestead, although by default it redirects you to your chosen host to do that. If you were to sign up directly through Homestead, you would not be able to sign up with passkey. If you’re using a password manager, the password would be saved for Homestead rather than the PDS. Homestead also supports logging in directly through it, although again, by default it will redirect you.

It’s up to you whether you’re comfortable passing your password through Homestead. I know that the application lives fully in your browser and no data actually goes through my server, but I have no expectation on you to trust that. I’ll repeat here that redirecting to your PDS is the default behavior, as any other OAuth client. But if you’re running your own Homestead, either on your own server or locally, you may want to log in directly through Homestead!

## What’s next

I would love for the outcome of this to be that you all go and create tons of different weird ways to manage your Tranquil PDS accounts. Contributions to Homestead are very welcome! But don’t hesitate to go make your own thing.

There’s no direct plans to incorporate Homestead into Tranquil, although that is a possible outcome. Or maybe we end up not having a built-in dashboard in Tranquil at all! Can’t wait to see where we end up.
