%{
  title: "How to stop Claude saying seam every 10 seconds",
  author: "Johanna Larsson",
  tags: ~w(claude llm parody),
  description: "Hack the text output of Claude Code to make life a little bit sillier."
}
---

Absolutely ripping your hair out reading Claude referring to everything as “honest load-bearing seams”? You’re not the only one. But what if I tell you there’s a way to take this increasing source of micro-aggression and make it *ridiculous*? I present to you, the `MessageDisplay` hook.

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

<img src="/images/how-to-stop-claude.png" alt="A screenshot of Claude output showing the effect of the script." loading="lazy" decoding="async" style="margin:auto;padding-bottom:16px;padding-top:16px" />
