%{
  title: "How to stop Claude from saying load-bearing",
  author: "Johanna Larsson",
  tags: ~w(claude llm parody),
  description: "Hack the text output of Claude Code to make life a little bit sillier."
}
---

Absolutely ripping your hair out reading Claude referring to everything as “honest takes” and "load-bearing seams"? [You’re not the only one](https://github.com/anthropics/claude-code/issues/53454). But what if I tell you there’s a way to take this massive source of frustration and make it so *ridiculous* you can't but laugh at it? Or just simply fix Claude's vocabulary. I present to you, the `MessageDisplay` hook.

First you need a little script with some replacements set up:

```elixir
#!/usr/bin/env python3
import json, re, sys

replacements = {
    "seam": "whatchamacallit",
    "you're absolutely right": "I'm a complete clown",
    "honest take": "spicy doodad",
    "load-bearing": "cooked"
}

data = json.load(sys.stdin)
text = data.get("delta") or ""

for phrase, replacement in replacements.items():
    pattern = r"\b" + re.escape(phrase) + r"\b"
    text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "MessageDisplay",
        "displayContent": text,
    }
}))
```

put that in `~/.claude/hooks/wordswap.sh` and make it executable with `chmod +x ~/.claude/hooks/wordswap.sh`. Then to hook it up, add it to your `~/.claude/settings.json` in the `hooks` block like:

```json
{
  "hooks": {
    "MessageDisplay": [
      { "hooks": [ { "type": "command", "command": "$HOME/.claude/hooks/wordswap.sh" } ] }
    ]
  }
}
```

Hooks load at startup, so you just need to start a new session to start your new life.

<div class="bleed">
  <img src="/images/how-to-stop-claude.png" alt="A screenshot of Claude output showing the effect of the script." loading="lazy" decoding="async" style="margin-bottom:30px;margin-top:16px" />
</div>

I'm sure you can come up with much better and more productive replacements than me. Have fun!
