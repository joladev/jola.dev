%{
  title: "The Magic of Daily Pull Requests: Why Smaller is Better",
  author: "Johanna Larsson",
  tags: ~w(management productivity coding),
  description: "A deep dive into why shipping small, daily pull requests transforms both your productivity and your team's collaboration, even though it requires rethinking how you structure your work."
}
---

There's something deeply satisfying about clicking that merge button. That moment when your code goes from "work in progress" to "shipped" never gets old. But here's what I've learned after years of building software: if you're not merging at least one pull request a day, you're probably making your life harder than it needs to be.

## The Miscommunication Problem

I recently had several eye-opening conversations with teammates that revealed a fundamental disconnect in how we think about development velocity. When I suggested aiming for a PR a day, the reaction was immediate and negative. "You want me to work faster?" "I can't put in more hours!" "This pace is unsustainable!"

But here's the thing: I wasn't asking them to work harder or longer. I was asking them to work differently.

The problem wasn't their work ethic or skill level. It was that we were speaking completely different languages. When I said "merge a PR daily," they heard "produce more output in less time." What I actually meant was "radically rethink how you structure your work."

## What Daily PRs Actually Mean

Let me be crystal clear: a PR a day doesn't mean cramming 16 hours of work into 8. It doesn't mean rushing through code reviews or cutting corners on quality. It means becoming ruthless about scope.

Instead of tackling that massive feature in one heroic effort, you break it down. You find the smallest possible piece that provides value and ship it. Then you find the next smallest piece. And the next.

This isn't easy. In fact, it's one of the hardest skills to develop as an engineer. Our natural instinct is to want to ship "complete" features. We want to show the full vision, the perfect implementation. But perfection is the enemy of progress.

## The Compound Benefits of Small, Frequent Merges

When you master the art of daily PRs, something magical happens. The benefits compound in ways you might not expect:

**Code reviews become a joy instead of a chore.** When a PR is 50 lines instead of 500, reviewers can actually understand what's happening. They provide better feedback. They catch more issues. The whole process becomes collaborative rather than adversarial.

**Collaboration accelerates dramatically.** When you're merging daily, other developers can build on your work immediately. No more waiting a week for that critical interface to land. No more merge conflicts that take hours to resolve.

**You feel more successful, which makes you more successful.** This might sound like pop psychology, but it's real. The psychological impact of daily wins cannot be overstated. Each merge is a small victory. These victories build momentum. Momentum builds confidence. Confidence builds better software.

**Stakeholders get actual visibility.** No more weekly standups where you say "still working on the user authentication system" for the third week in a row. Instead, you can point to concrete progress: "Monday I shipped the password validation. Tuesday I added the email verification flow. Wednesday I integrated with the notification service."

## The Art of Scope Cutting

So how do you actually achieve this? How do you take a feature that seems like it needs a week and ship part of it today?

Start by questioning every assumption. That new dashboard feature? Maybe you don't need all five widgets on day one. Ship one widget. That API integration? Perhaps you can start with read-only access before implementing writes.

Look for natural boundaries in your work. Can you ship the data model separately from the UI? Can you implement the happy path before handling edge cases? Can you deploy behind a feature flag so the code is merged even if the feature isn't live?

The key is to always be asking: "What's the smallest thing I can ship that moves us forward?"

## The Daily PR Challenge

I'll admit it: hitting a PR every single day is ambitious. Some days you're in meetings. Some days you're debugging production issues. Some days you're doing research or design work.

But even if you can't hit it every day, the mindset shift is what matters. A PR every other day beats one every week. A PR every three days beats one every two weeks. The exact frequency matters less than the commitment to keeping changes small and shipping frequently.

The real transformation happens when you internalize this approach. When you automatically think in terms of small, shippable increments. When you instinctively look for ways to break down work rather than batch it up.

## Making It Happen

If you're convinced and want to try this approach, start small (how fitting). Pick your next feature or bug fix and ask yourself: "How can I ship part of this today?"

Don't aim for perfection. Aim for progress. Ship something small. Then ship something else small tomorrow. Before you know it, you'll have shipped more in a week than you used to ship in a month.

The path to shipping great software isn't through heroic efforts and massive PRs. It's through consistent, incremental progress. One small PR at a time.

Can you merge a PR today?
