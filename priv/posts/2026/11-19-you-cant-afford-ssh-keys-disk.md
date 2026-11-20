%{
  title: "You can't afford to keep your SSH keys on disk",
  author: "Johanna Larsson",
  tags: ~w(security ssh password-manager),
  description: "Why you want to delete your SSH keys from disk, and how to use Bitwarden's SSH agent to do it."
}
---

Although it's clear to me that some of the [panic is unwarranted](https://shelf.cafe/items/did:plc:bvraa6gajy4tfr3eh2sisdkr/3myom4aabu2nc), all the recent security vulnerability reports and company breaches are a good reason to think about what you're doing to avoid risk, and to mitigate exposure if something bad happens.

I'm a pathological self-hoster and I've been running all kinds of systems, from old toy projects to fun tools, and over time I've accumulated a lot of them. This has changed in the last couple of months, where I've instead been pruning my running services. I've taken down unused old apps, because anything can be an entry point into your system. And they were _unused_ anyway. I've also moved most of services behind my Tailscale, with some judicious use of `tailscale funnel` to poke little holes for specific things that do need to be publicly accessible. And I've been obssessively updating everything on my servers that can be updated.

That brings us to my personal computer. I've been trying to do the same kind of due diligence that I did for my servers, on my personal devices. I have been a long time user of password managers, and I recently wrote about [moving to Bitwarden](https://jola.dev/posts/migrating-from-1password-to-bitwarden), and I am careful to always enable 2FA or passkeys on every service I use. But one area I've fallen behind is **SSH keys**.

## A better approach to SSH keys

I was keeping copies of my private keys in my password manager, for safe-keeping, but I was still using the version on disk, loaded into memory with `ssh-add`. After reading articles like [I deleted all my SSH keys](https://shelf.cafe/items/did:plc:bvraa6gajy4tfr3eh2sisdkr/3mzzdhgqno2fu), I finally decided to take the next step and get them off disk.

I knew that for this to work for me, it had to be easy to use and the disruption had to be minimal, and so although things like the OSX Secure Enclave sounds incredibly cool, I needed something with better ergonomics. I already had Bitwarden set up, with the keys in it, and so that's the approach I ended up taking, and it has worked great for me.

## Setting up the Bitwarden SSH agent

Ok, let's go through the steps. First, make sure your private keys are in Bitwarden. If they are not, you'll want to import them. Note that the Bitwarden UI for importing SSH keys is a bit awkward. 

1. Create a new SSH key in Bitwarden, it'll automatically generate one for you.
2. Copy your existing private key into your clipboard, eg `cat ~/.ssh/id_rsa | pbcopy`.
2. On the Private Key header in the edit form, at the very far right of the asterisks hiding the value, there's an upload icon, click it.
3. Your private key has been imported. Give it a good name and save.

Once you're done with that, you can now move on to the next step, which is enabling the Bitwarden SSH agent. Note that these instructions are for the direct install, if you installed it through the App Store I think the [path is different](https://community.bitwarden.com/t/ssh-agent-in-macos-not-working/82609/8). Go to Preferences, App settings (all accounts), and find the checkbox for "Enable SSH agent". You'll also get the option of choosing how often it prompts you for permission, when something wants to use the key. I went for whenever the vault is locked, which I have set to every 4 hours, balancing security with convenience.

Next, add to your `~/.ssh/config` file:

```
Host *
  IdentityAgent ~/.bitwarden-ssh-agent.sock
```

This tells `ssh` to use the Bitwarden SSH agent. This applies globally, so anything that calls `ssh` should now check the agent. Separately, you'll want to add this to your terminal config file, eg `.zshrc`:

```
export SSH_AUTH_SOCK=~/.bitwarden-ssh-agent.sock
```

This ensures anything that needs the SSH agent in your terminal, that isn't `ssh`, also go to the right place. This covers tools like `ssh-keygen`. Okay, now try it out with `ssh-add -L`. This should list all the keys loaded into `ssh-agent`. If you're confident you've copied all of your keys into your password manager, you can now delete the ones on disk.

## Bonus: git commit signing

Git commits traditionally contain author information, but no proof that the author is who they say they are. This means it's trivial to impersonate someone else in a commit. It's still mitigated by the fact that git repositories generally have access controls, so a third party would not be able to push commits in the first place, but there is also a mechanism available for proving that the git originated from the claimed author: commit signing.

In the past, this was limited to GPG keys, but modern git supports signing using SSH keys. So I've set this up too, using a dedicated key that only has that job. This means that creating the commit and pushing it to the repo requires _two_ separate SSH keys, and each one has to be authorized separately.

```bash
git config --global gpg.format ssh
git config --global user.signingkey "key::$(ssh-add -L | grep 'YOURKEYNAME')"
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

Go to a repo and create a commit, then run `git cat-file -p HEAD`, and you should see your signature there.

To have forges recognize your signature you have to teach them what it is. For Github that means going to [https://github.com/settings/keys](https://github.com/settings/keys) and adding it as a signing key. Tangled automatically trusts your configured SSH keys as signing keys. Gitea and Forgejo require some extra steps to trust your key, just follow their instructions at `/user/settings/keys`.

## My experience after a couple of weeks

I've adjusted quickly. Everything just works out of the box, the only added friction is that now and then Bitwarden prompts me for permission to use keys, which if it's unlocked just means clicking "approve" on a dialog. If it's locked, I can unlock it with touch ID.

If any Bitwarden employees happen to be reading this, it would be nice if instead of clicking approve, I could use touch ID to approve use of the key. Or at least by hitting enter. As it is, I always have to move to the touchpad to approve. It would also be great if I could separately configure the vault lock interval and the same interval for keys. But that's just minor requests, overall it works just great for me, and it's not too disruptive.

And now I get to sleep a bit easier!
