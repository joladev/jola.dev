%{
  title: "You can't afford to keep your SSH keys on disk",
  author: "Johanna Larsson",
  tags: ~w(security ssh password-manager),
  description: "Why you want to delete your SSH keys from disk, and how to use Bitwarden's SSH agent to do it."
}
---

Although it's clear to me that some of the [panic is unwarranted](https://shelf.cafe/items/did:plc:bvraa6gajy4tfr3eh2sisdkr/3myom4aabu2nc), all the recent security vulnerability reports and company breaches are a good reason to think about what you're doing to avoid risk, and to mitigate exposure if something bad happens.

I'm a pathological self-hoster and I've been running all kinds of systems, on top of maintaining all of my old toy projects, but I've spent the last few weeks pruning my running services. I've taken down unused old apps, because anything can be an entry point into your system. And they were _unused_ anyway. I've also moved a lot of services behind my Tailscale, with some judicious use of `tailscale funnel` to poke little holes for specific things that do need to be publicly accessible. And obssessively updating everything on my servers that can be updated.

That brings us to my personal computer. I've been trying to do the same kind of due diligence that I did for my servers, on my personal device. I have been a long time user of password managers, and I recently wrote about [moving to Bitwarden](https://jola.dev/posts/migrating-from-1password-to-bitwarden), and I am careful to always enable 2FA or passkeys on every service I use.

But one area I've fallen behind is **ssh keys**.

## The basics of SSH

SSH keys are a type of public key cryptography, where you generate a private and a public key. The public key can be shared widely, and can be used by others to check the signature of something you have signed with the private key. This is how you're able to `ssh` into a server, or push to a git remote like `jola.dev@knot.cove.town:did:plc:ynnmdn2g6bxogqerh3er4p4v`. The server has your public key, and only you have your private key.

By default these keys are stored on disk, in the `~/.ssh`, with strict permissions set. Hopefully you've set a password on your private key too, encrypting it. You can load them into `ssh-agent` by running `ssh-add`, and this saves you having to type in that password all the time.

But even with a password set, your private key is at risk. Anything that can read the `~/.ssh` folder can read the key. If someone gets access to your private key, even with a password set, you have to assume that they can now access everything that you can. Separately, with your key loaded into `ssh-agent`, anyone able to run commands as you can run `ssh root@yourserver` and get access to your server, without being prompted for a password.

## Where to put the keys instead

I had already stored copies of my private keys in my password manager, for safe-keeping, but I was still using the version on disk, loaded into memory with `ssh-add`. After reading articles like [I deleted all my SSH keys](https://shelf.cafe/items/did:plc:bvraa6gajy4tfr3eh2sisdkr/3mzzdhgqno2fu), I finally decided to take the next step and get them off disk.

I knew that for this to work for me, it had to be easy to use and the disruption had to be minimal, and so although things like the OSX Secure Enclave sounds incredibly cool, I needed something with better ergonomics. I already had Bitwarden set up, with the keys in it, and so that's the approach I ended up taking, and it has worked great for me.

## Setting up the Bitwarden SSH agent



## Bonus: git commit signing

## Conclusion
