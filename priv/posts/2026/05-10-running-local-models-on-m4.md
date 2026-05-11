%{
  title: "Running local models on an M4 with 24GB memory",
  author: "Johanna Larsson",
  tags: ~w(elixir llm qwen llmstudio),
  description: "Experiments with getting usable outputs out of local models on a standard Macbook"
}
---

I’ve been experimenting with running local models on and off for a bit and I’ve finally found a setup that seems to work reasonably. It’s nothing like the output of a SOTA model, but the excitement of being able to have a local model do basic tasks, research, and planning, more than makes up for it! No internet connection required! Not to mention that it’s a way of reducing your dependence on big US tech, even if just a tiny bit.

I gotta say though, it’s not easy to get this stuff set up. First you have to choose how you’re running the model: [Ollama](https://ollama.com/), [llama.cpp](https://github.com/ggml-org/llama.cpp) or [LM Studio](https://lmstudio.ai/). Each one comes with its own quirks and limitations, and they don’t offer all the same models. Then of course, you have to pick your model. You want the best model available that fits in memory and still gives you enough headroom to run your regular assortment of Electron apps, not to mention something where you can have at least a 64K context window, but ideally 128K or more. Most recently I’ve tried Qwen 3.6 Q3, GPT-OSS 20B, Devstral Small 24B, which all technically fit in memory but were in practice unusable, and Gemma 4B that would run fine but really struggle with tool use.

Then there’s a plethora of configuration options to tweak. From the more well-known, like temperature, to more esoteric options like K Cache Quantization Type. Many of these tools come with a basic recommended set of options, but the appropriate ones can depend on things like whether you’re enabling thinking or not!

## Qwen 3.5-9B (4b quant)

`qwen3.5-9b@q4_k_s` ([HuggingFace link](https://huggingface.co/unsloth/Qwen3.5-9B-GGUF)) is the best model I’ve gotten working with a reasonable ~40 tokens per second, thinking enabled, successful tool use, and a 128K context window, running on LM Studio. Compared to a SOTA model, it gets distracted more easily, sometimes it gets stuck in loops, it’ll misinterpret asks etc. But it’s surprisingly good for something that can run on a 24GB Macbook Pro while leaving space for lots of other things running too!

These are the recommended settings for thinking mode and coding work:

>
>
>
> Thinking mode for precise coding tasks (e.g., WebDev):
>
> temperature=0.6, top_p=0.95, top_k=20, min_p=0.0, presence_penalty=0.0, repetition_penalty=1.0
>

To enable thinking I also had to select the model, go to configuration, scroll to the bottom of the Inference tab, and add `{%- set enable_thinking = true %}` to the Prompt Template.

I’ve been using it through both [pi](https://pi.dev/) and [OpenCode](https://opencode.ai/). I still haven’t quite made my mind up on with one I prefer. Pi feels a bit snappier, but although I really appreciate the idea of the harness building itself and all that customization, I can’t help but wish it came with some sensible defaults. I feel like you could easily end up spending more time tweaking your pi set up to be just right, than you do on your actual projects!

## Pi setup

Here’s the `~/.pi/agent/models.json`:

```elixir
{
  "providers": {
    "lmstudio": {
      "baseUrl": "http://localhost:1234/v1",
      "api": "openai-completions",
      "apiKey": "lm-studio",
      "models": [
        {
          "id": "qwen3.5-9b@q4_k_s",
          "reasoning": true,
          "compat": { "thinkingFormat": "qwen-chat-template" }
        }
      ]
    }
  }
}
```

and to hide the distracting thinking, add `"hideThinkingBlock": true` to your `~/.pi/agent/settings.json`.

## OpenCode setup

`~/.config/opencode/opencode.json`

```elixir
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "lmstudio": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio (local)",
      "options": {
        "baseURL": "http://127.0.0.1:1234/v1"
      },
      "models": {
        "qwen3.5-9b@q4_k_s": {
          "name": "Qwen 3.5 9B Q4_K_S",
          "tools": true,
          "context_length": 131072,
          "max_tokens": 32768
        }
      }
    }
  },
  "model": "lmstudio/qwen3.5-9b@q4_k_s"
}
```

## Comparison with SOTA models

A model like Qwen 3.5 9B (Q4) is nowhere near being able to independently solve complex problems over longer period of time, like SOTA models are. There’s no point in asking it to build an entire app in one go, you’ll just burn your thighs without getting anything out of it.

What does work is a more interactive workflow where you’re clearly communicating with the model step by step, and giving it a lot of guidance. I’m sure that sounds pointless to many of you, why use a model where you have to babysit it as it works, but I actually found that it encouraged me to be more engaged. The downside to working with SOTA models is that they make it too easy to offload all cognitive effort, even where you’re trying to actively prevent that from happening.

With the local modal I have to take on a lot more of the thinking and planning, I have to be a lot more specific, but it will still act as a research assistant, a rubber duck, and a savant with instant recall of a lot of programming language details and command line evocations. It’s not the 10x productivity boost that the big AI companies market, but it’s something, and it’s interesting.

To give you an idea of some things that work and don’t, here are some very basic examples.

### Example 1:

I wanted to bump the Elixir linter `credo` to the latest version and I got warnings out of my code. As an experiment, I asked Qwen to take a look.

```elixir
me:
  run mix credo --strict and suggest how to solve it, don't edit

Qwen:
	Credo Warnings
	There are 4 warnings in your test files. The issue is using length/1 to check if lists are non-empty. Credo recommends comparing against an empty list instead.
	Warnings:
	1. test/jola_dev_web/controllers/blog_controller_test.exs:11
	   - assert length(conn.assigns.posts) > 0
	2. test/jola_dev_web/controllers/blog_controller_test.exs:22
	   - assert length(conn.assigns.posts) > 0
	3. test/jola_dev/blog_test.exs:10
	   - assert length(posts) > 0
	4. test/jola_dev/blog_test.exs:23
	   - assert length(tags) > 0
	How to Fix
	Replace each length(list) > 0 with list != []:
	blog_controller_test.exs:
	# Line 11
	assert conn.assigns.posts != []
	# Line 22
	assert conn.assigns.posts != []
	blog_test.exs:
	# Line 10
	assert posts != []
	# Line 23
	assert tags != []
	This is more idiomatic in Elixir and avoids the overhead of computing the list length.
```

I asked Qwen to make the edits and it did 4 parallel edits, very clean. Overall this was a very simple task that I could’ve done myself by tabbing back and forth between the terminal and my editor to get the line numbers to edit. Not a big difference in effort, but nice and convenient.

### Example 2:

After some dependency bumps I had a dependabot PR with git conflicts that dependabot for some reason was refusing to rebase. I pulled it down, rebased, and asked Qwen to take a look. It was a very simple conflict to resolve, just take the newer version of each, and the model recognized that.

```elixir
I can see the conflict. Here's what's happening:
HEAD (your current branch):
- sentry: 13.0.1
- tailwind: 0.3.1
Other side (commit being rebased):
- sentry: 12.0.3
- tailwind: 0.4.1
You have divergent dependency bumps. Here are your options:
Option 1: Take both updates (recommended)
- Keep sentry 13.0.1 from HEAD
- Keep tailwind 0.4.1 from the other side
- This gives you the latest of both deps
Option 2: Take only sentry update
- Keep sentry 13.0.1
- Keep tailwind 0.3.1
Option 3: Take only tailwind update
- Keep sentry 12.0.3
- Keep tailwind 0.4.1
Which approach do you want to take?
```

However, when asked to make the change, it forgot to make the edit and instead just tried to add the changes and continue the rebase, with the conflict markers still in place.

```elixir
> Thinking: The user wants to take both updates - sentry 13.0.1 and tailwind 0.4.1. I need to resolve the conflict by keeping the HEAD version for sentry and the other side version for tailwind. I'll use git add to stage the resolved file.
----
# Stage resolved mix.lock and continue rebase
$ git add mix.lock && git rebase --continue
Vim: Warning: Output is not to a terminal
Vim: Warning: Input is not from a terminal
"~/workspace/mixtli/.git/COMMIT_EDITMSG" 32L, 1047BBump tailwind from 0.3.1 to 0.4.1
Bumps [tailwind](https://github.com/phoenixframework/tailwind) from 0.3.1 to 0.44.1.
- [Changelog](https://github.com/phoenixframework/tailwind/blob/main/CHANGELOG.mmd)
- [Commits](https://github.com/phoenixframework/tailwind/compare/v0.3.1...v0.4.11)
```

Additionally it failed to recognize that `git rebase --continue` opens an editor, and OpenCode then proceeded to hang, although that might just have been a one-off.

## Conclusion

Anyway, LLMs are incredibly flexible and there’s a million things even a local model could do. Your imagination is the limit. Local models have serious tradeoffs, but they come with some pretty attractive benefits:

- No internet connection required, you can work on the plane!
- The cost is limited to the electricity you’re using, assuming you were gonna buy a computer anyway. No subscription required.
- There’s still going to be a serious environmental cost of training these models, but the open model companies are nowhere near the top of the list in environmental impact, and using your own hardware means less data centers.
- It’s fun to tinker.

LLMs have had a huge impact on our world, and much of it not great, but it’s obvious that they’re here to stay. Experimenting with local models feels like a more sustainable and positive way to interact with this technology. And honestly, it’s a lot of fun, even when it does the wrong thing!
