%{
  title: "If the Goal is Resiliency, Defensive Programming is Your Enemy",
  author: "Johanna Larsson",
  tags: ~w(management productivity coding),
  description: "A counterintuitive exploration of why defensive programming with excessive error handling creates less resilient systems than those designed to fail fast and explicitly."
}
---


# If the Goal is Resiliency, Defensive Programming is Your Enemy

This may sound incredibly unintuitive, but if you want to build resilient software, conditionals are your worst enemy.

I've worked on enough projects to see this pattern play out over and over. Teams start with the best intentions, trying to handle every edge case, wrap every operation in error handling, and provide fallbacks for every possible failure. But what they end up with is something far worse than the occasional crash: a system that lies to you.

## Two Philosophies of Software Design

Let me paint you a picture of two different projects I've encountered, each following a completely different philosophy.

**Project 1: The Defensive Approach**

This team believed in defensive programming with religious fervor. Every line of code was wrapped in error handling. Every exception caught and swallowed. Every piece of missing data had a default behavior.

When they looked up a session in the browser and it didn't exist, they'd return an empty object. What if the user object in the session was nil? No problem, just use a default value! And just to be absolutely sure nothing could go wrong, they'd wrap the whole thing in a try-catch block.

The codebase became a maze of conditionals. Nobody knew which fields were supposed to exist and which ones were optional. The team's focus was entirely on preventing incidents from happening at all. But when things inevitably went wrong, everyone was completely lost. The errors had been caught and handled so many times that the original problem was buried under layers of "defensive" code.

**Project 2: The Explicit Approach**

This team took a radically different approach. They encoded every variant directly into their codebase. Every line of code expressed clearly whether a field was guaranteed to exist or not. No hidden assumptions, no silent defaults.

Sure, they had bugs. Sometimes data wasn't where it was supposed to be. But when that happened, the system failed immediately at the point of the problem, not three layers deep in some unrelated module. Every feature was built with the explicit acknowledgment that things can and will crash. The focus wasn't on preventing incidents but on recovering from them quickly.

## What Actually Happens in Practice

Here's what I've learned after dealing with both approaches in production systems.

Project 1 creates systems that silently degrade. Users get blank screens, incomplete data, or weird behavior that's almost impossible to reproduce. Your monitoring shows everything is "fine" because no exceptions were thrown. You're not debugging real problems anymore; you're debugging ghosts. Issues that happened three layers deep in your abstraction, masked by well-meaning error handlers that turned a clear failure into a subtle corruption of state.

Project 2 creates systems that fail fast and loud. When something breaks, you know exactly where and why. Your error monitoring lights up like a Christmas tree, but here's the thing: you can trace the issue back to its source in minutes instead of hours. The stack trace tells you the real story, not some sanitized version of it.

## The Counterintuitive Truth

The real kicker? Project 2 systems actually have fewer outages. Not because they're more defensive, but because they're more honest about what can go wrong.

When your system fails fast, you find and fix problems quickly. When your system silently handles errors, those problems compound. That defensive nil check you added? It's now hiding the fact that your authentication system is returning malformed data. That try-catch block around your database call? It's masking connection pool exhaustion until your entire system grinds to a halt.

## A Better Way Forward

Stop trying to catch every possible error. Start being explicit about what your code expects, and let it crash when those expectations aren't met. This doesn't mean being reckless. It means being honest.

If a function expects a user ID, don't provide a default value when it's missing. If a service call can fail, make that failure explicit in your type system or return values. When something goes wrong, let it bubble up to a level where it can be meaningfully handled, with all the context intact.

Your monitoring will be more accurate. Your debugging will be faster. And counterintuitively, your system will be more reliable because problems get fixed instead of hidden.

Your future debugging self will thank you when you're looking at a clear error message with a full stack trace at 3 AM, instead of trying to figure out why users are seeing empty screens with no errors in the logs.

Have you experienced this in your own projects? I'd love to hear about your experiences with fail-fast versus defensive programming approaches. The tension between preventing errors and handling them properly is one of the fundamental challenges in building reliable systems, and I'm always curious to hear how other teams navigate it.
