%{
  title: "How to hit your Claude weekly limit so you can go outside and touch grass",
  author: "Johanna Larsson",
  tags: ~w(claude llm parody),
  description: "The secrets to breaking free from the constant "
}
---


Like much of the tech community, I haven’t slept since Claude 4.0 came out. My life has been a haze of maintaining 14 separate sessions running at all times, context loading every 20 seconds, feeding myself into the machine. My existence has come down to providing a constant stream of “ideas” for Claude to build.

But then something magical happened. 

<img src="/images/weekly-limit.png" style="margin-bottom:16px" />

The spell was broken… I stumbled out of my apartment and saw the sun for the first time in months. It was glorious. And I’m here to help you get there too.

# Start 10 sub agents for every task

This is a classic, and of course genuinely improves the quality of results, but the trick is to not just use it for tasks like “Investigate the optimal way of creating a sandboxed environment to run our code”, but also for tasks like “run biome to format the code”.

No basic linting command done a single time can be done better than one done *ten* times.

# Install all of the MCPs

Now I realize you might be misreading this as "install a lot of MCPs", but what I actually mean is that you install every single MCP that has ever been created. Ask Claude to write a `.mcp.json` that contains every single one. Make sure to get the really good ones, like the PostHog one that has 115 tools and uses 70,659 tokens. Thank you PostHog! We're off to a great start!

# Maximize effort

Anthropic defaulted the world to medium effort, but if you’re not making an effort, what are you even doing. Medium effort is for my exercise routine. No, we need to do better than that. And we’re not talking about `/effort high`, cause why go high when you can go `max`.

Max effort is such a powerful tool in burning through your tokens that Anthropic won’t even let you set it permanently, it’s per session, so remember to keep activating it.

Additionally, they added this thing called “adaptive reasoning” where Claude decides how much to think about something before doing it. We’re having none of that. We’re always going to think the maximum amount about *everything*. Set the flag `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`.

# Run separate sessions and only use each one once per hour

Start 10 separate sessions and rotate through them, using the tricks we’ve learned so far to build up context efficiently. But be careful never to re-use a session within an hour. On a Max plan, your session is getting cached with a one hour TTL. That means that if you have an 800K context session and you send multiple messages within a one hour interval of each other, you’re only paying the token cost difference for those messages. But if you let the cache expire between each message, you pay the entire 800K session cost *for each message*.

Now we’re really cooking.

# Resume a lot

Of course, having to wait an entire hour between messages is going to really slow us down. Which is why we’re bringing in our last and most powerful weapon: resume.

You might think that resuming a session that has a live cache would resume the live cache too, but you’d be wrong! Anthropic in their infinite wisdom have given us the ultimate tool for hitting your usage limits so you can *just stop already*. Take a 999K session and CTRL+C, CTRL+C, and then copy paste the “resume” message. 

# You’ve used 100% of your weekly limit

Practice a bit and you’ll be able to hit 1M tokens in usage every few seconds! You’ll run out of usage in no time at all. You can stop now. You can take a break. Breathe. Claude is not waiting for you anymore. 

And you’ll get to experience that magical thing other people talk about: going outside.
