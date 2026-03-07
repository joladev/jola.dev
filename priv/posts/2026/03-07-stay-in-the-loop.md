%{
  title: "Stay in the Loop: How I Actually Use Claude Code",
  author: "Johanna Larsson",
  tags: ~w(claude llm productivity coding),
  description: "How to multi-task Claude Code while staying in the loop."
}
---

**tl;dr** There are only two modes: planning and executing. You can never execute without having planned first. When execution goes off-track, you stop and go back to planning. That's it.

---

Described this way of working to a coworker and although I don’t think this is revolutionary, it felt like it would be worth a blog post. This has been working pretty well for me, running 6+ concurrent sessions at different stages of planning and executing. It does require a lot of context switching, but the overall output has been great.

# The workflow

You don't start by asking Claude to take action. You start by asking it to load **context**. Read Linear tickets, Notion docs, relevant files, the codebase. The goal is to build up a shared picture of the world before any work happens.

*For smaller tasks you can skip the initial context building step, but it often has to happen during planning anyway.*

Next up: give it the **task**. Tell it to research, investigate, and come back with descriptions, backgrounds, pros and cons. Crucially: no edits, no actions, not even plan mode yet. If it tries to jump ahead, hit the escape button immediately and tell it to get back on track. The goal is to have a shared understanding of the problem and a rough approach you both agree on. If there’s even a hint of ambiguity in the output, stop and ask for clarification. Only when you're completely aligned, every code path has been investigated, do you tell it to go into plan mode.

*If you’re using the 200K context window version, you probably want to choose accept and reset context. If you’re on the 1M version, probably fine not to!*

Finally: **execution**. You’ve got a plan you believe in, all the research has been done. Send Claude off to go execute and set the mode to auto-accept. You can go grab a cup of coffee now. If the planning was good enough, it should work 🤞 Come back when it’s done and verify. If the plan worked out you’re done! If it did not, fight the temptation to accept Claude’s quick fix suggestions. Go back to planning, turn off auto-accept. Reject any attempts to just “make it work”. This is where things go off the rails. Stop and tell Claude to step back and think it through. Don’t let it make edits or go back into plan mode. Work with it until you feel like you have a good understanding of what went wrong, how we can fix it, and what the implications are of that fix. Then once you’re confident in the solution: back to execution.

That’s it. Plan → Execute. If you’re not done yet, back to plan. Put yourself squarely in the loop.

# Why this works

Human communication, human language, is ambiguous and we often end up in situations where you and another person think you agree on something, but you actually have completely different understandings of what that thing is. It’s only when you dig into the details that you realize your lack of alignment.

LLMs use this lossy and vague form of communication to do everything. By forcing every detail into the context and the plan you remove ambiguity and increase the chances of the tool doing the thing you want it to do.

And why reject Claude’s quick fixes as the end? This is all anecdotal, but this is where I experience the most friction. Instead of stepping back and reflecting over the failures and issues, and trying to figure out the core of the issue, in this situation Claude seems to default to try to quickly solve it, without putting in much effort. Who knows why, but you can see the pattern if you look for it. Break out of that failure loop by asking it to _think_.

# Human in the loop

This is moving in the opposite direction of [Ralph Wiggum](https://ghuntley.com/ralph/) or [Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04). Instead of brute forcing it and having the LLM bash its virtual head against the wall, you take on the job of keeping it on track. Not by sitting by the computer watching it, not by reviewing every individual diff before approving, but by inserting yourself at the crucial points in the development flow. Don’t let it execute until you’re confident the plan is right. Don’t let it fall into the trap of quick fixes.

You do have to jump back and forth between sessions, switching context, but you’re gonna have lots of opportunities to let a few sessions load context or investigate the codebase while you review another one’s output, leading to pretty effective parallelism. LLMs don't make you more productive without investing in finding workflows that

The models will get better. You'll still need to set the direction.
