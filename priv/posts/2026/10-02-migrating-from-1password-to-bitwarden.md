%{
  title: "Migrating from 1Password to Bitwarden",
  author: "Johanna Larsson",
  tags: ~w(passwordmanager migration bitwarden 1password),
  description: "After 1Password's recent political statement, I canceled my subscription and switched to Bitwarden."
}
---

In light of recent events I've canceled my 1Password yearly subscription, after 10 years as a loyal user. This was not a decision I made lightly, I’ve got everything in my password manager and the muscle memory for using it is deeply ingrained in me.

After much procrastination I finally took the plunge a month ago and it turns out, **it was actually pretty easy to switch**. And it came with some upsides too, Bitwarden is almost half the price of 1Password on the yearly plan.

## Migration guide

There are different approaches to this, but I’ve only tried the one: migrating on an iPhone. You can also do it using android or using the desktop apps, but I haven’t tried those!

**Step 1** is setting up your Bitwarden account. You can do this for free, you don’t need to pay to do the migration, although to get access to the TOTP features you will need to set up a subscription. Once you have your account, get the iPhone app and log in.

**Step 2**, go to the 1Password app on your phone and click on the top left, go to Settings, go down to Advanced, and click “Start Export”. Going through the export wizard it should detect the Bitwarden app and offer it as an export destination. Once done, you’ll have a copy of your data in Bitwarden.

Installing the Bitwarden app on your computer and logging in should sync everything over. **You’re done!**

## Some notes on migration

There were a few little awkward things about the process. One is well-documented, vaults don’t really translate, so all your entries end up in the same Bitwarden vault. For me that put a massive amount of stuff in the same place, 10 years worth of mostly inactive accounts and old notes. I spent a bit of time organizing it into folders and archiving old things. Maybe that was self-inflicted really.

I also did spot some entries that had not exported properly. All of it was from 2019 or earlier, so I don’t know if there was something weird with the 1P records from back then, but they showed up as empty in Bitwarden. Fortunately discontinuing your 1P subscription doesn’t lock you out of your data, it just prevents you from adding new things. So you can keep the old app around as a backup for a while before you’re confident all your data is there.

## After a month of use

There are a few little UX things I miss, like hitting enter to use a passkey. And I still have to use 1Password for work, so I now have both apps fighting over control of password fields on my phone. But those are minor nits, nothing to discourage you from switching.

I’m very happy with Bitwarden as an alternative to 1Password. Hopefully it’ll last me at least 10 years too! If you’re looking for alternatives though, I’ve heard good things about KeyPassXC and, if you’re in the Apple ecosystem, the built in Passwords app.
