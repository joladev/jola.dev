%{
  title: "AI is antithetical to learning",
  author: "Johanna Larsson",
  tags: ~w(ai llm learning),
  description: "LLM agents can write a lot of code for you very fast, but they also take away opportunities to learn and grow."
}
---

Spend enough time with LLMs and you start noticing certain patterns. Maybe you’re working on a codebase and you want to upgrade a dependency or language version, redesign some component, or add new features. You ask the LLM how to do it, and it gives you a brief description and then finishes with “Do you want me to start?”. Sometimes it doesn’t even bother responding, it just edits the code for you. You ask it for the commands to look up DNS records for a domain, and it responds with the DNS records. Not the commands. And it always finishes by suggesting another thing it could do. Guiding you forward, but always keeping you one step removed from what is actually going on.

If you’re very disciplined you can stay involved, by carefully crafting your prompts, inspecting all the actions taken in the harness (actions that are less visible with every harness update), and by stopping the agent when it goes off the rails. But it requires just that, discipline. All that willpower to stay involved and not just give in to the siren song of agentic coding. But you’re working against the tool. A tool that is designed to encourage you to rely on it for everything, until you don’t even look at the code anymore. Until you can’t edit the files yourself anymore.

Until you become utterly dependent on it.

## A sharp tool

This isn’t intrinsic to LLMs as a technology. This is the result of companies whose goals are not aligned with humans learning things, or humans staying engaged and in the loop. To motivate their astronomical valuations they need AI to replace everything else. It has to be used for everything. For these companies to ever become profitable all the software engineers in the world need to become *dependent* on their products. They want to be the landlord and for the rest of the world to pay them rent.

If you’re willing to take the role of agent manager, producing ideas to feed the hungry machine with, providing the agent swarm with high level direction, and maintaining the software factory, then you’ll see the models slot perfectly into this. That’s what they’re being trained for, that’s what they’re being designed for. To avoid confusion, this article is not about whether agentic coding is a good thing or not. It’s clear that the industry is moving in that direction. But I still want to learn things, for the sake of learning them. Whether or not you would say that that’s still necessary.

When all you want is to tap into the massive amounts of information stored in the model, you’ll find yourself constantly fighting against it. If all you want is to build an intuition of how a content addressed encoding algorithm works, all the information is in there. It should be absolutely possible to use models to teach you things. They’re just not primarily designed for that.

## What you can do

If you still want to take on the challenge to learn using LLMs, here are some basic guidelines I would suggest you apply.

1. Lock down the agent harness so it can’t edit or run commands that are not for reading. Every command it runs for you is a missed opportunity to learn and build up muscle memory for interacting with your computer.
2. You basically have to beg it to read human sources, it will always try to clone repos and read the source code. Keep asking it to provide you with human sources.
3. Include in your system or project prompt clear instructions for what you’re doing. Specify whether you ever want it to show you code samples, or just provide sources and information.
4. The less you give into the temptation of the agent doing things, the more you learn, even when it’s annoying or frustrating. Toil is important to humans. Toil helps us learn and grow.

And as always, apply extreme skepticism to everything it outputs. LLMs are trained to always express every statement with complete confidence. That helps the model companies sell their technology. It doesn’t help you.

The upside if you can get it to work for you is that you’ve got a generator of an infinite amount of learning material. It can provide you with content designed for you, and it can adjust and tweak things as you go. In the ideal case, it’s like having a book on programming that you can ask questions to, that can create exercises for you, that can adjust the language and content to your level. That can teach you about the most obscure concepts, even for things that have little to no documentation.

It’s a hint of what we could have had, if things had happened differently.

## A better world

I don’t think we should give up the science and technological concepts that underpin large language models to the VC-backed startups locked in a struggle to the death for supremacy. I also don’t think that the “good version” of LLMs is profitable enough to motivate the massive capital expenditure in developing them. But I’m still hopeful that we can find a better way to do this. Some day.

I also want to make it clear that I’m not writing this as a criticism of people who enjoy agentic coding. This article is just about learning. 

For now, follow your heart. Use LLMs if you find them useful, and you find it acceptable. If you don’t, don’t. But no matter your approach to it, remember to grow and learn. It’s worth it.
