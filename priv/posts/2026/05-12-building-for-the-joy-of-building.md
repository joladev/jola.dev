%{
  title: "Building for the joy of building",
  author: "Johanna Larsson",
  tags: ~w(builder coding joy),
  description: "My path into programming and why I've been obsessed for 20 years."
}
---

My path into coding wasn’t straightforward, it didn’t start with formal education or learning from friends or family. I got some limited access to the internet in my teens and, like many of us back then, I was introduced to HTML through services like Angelfire, where I could set up a website with blink tags and way too many animated images.

It took a while to take, though. I had some classmates in high school who took classes in programming and got into C. I gotta say, I was not impressed. I even remember saying I wasn’t interested, when they were trying to convince me how cool this was. I categorically stated I would never be interested in something like this.

It wasn’t until my early 20s, when my dad wanted a website for his business, that I started to take my first real steps into programming. It started out with a basic website, some HTML and CSS. I bought some basic O’Reilly book and taught myself enough to get it up and running. And just like that I was hooked. Because now that I had a website, I needed somewhere to host it, right? So I get another O’Reilly book to teach myself Linux sysadmin. Now we’re really cooking. Add some interactivity on top of that? O’Reilly book on JavaScript. This isn’t really meant to be advertising for O’Reilly, it’s just what I had back then. Programming books. And I devoured all of it.

I did end up getting a degree, not computer science because I didn’t have the qualifications, but computer science adjacent. And I started my career.

It’s been 14 years now since I got my first job as a professional programmer, and the joy that I felt building that first website has never left me. Sure, I’ve had periods of time where I spent less time coding, but it’s never long before I feel that urge to create something.

It’s always been undirected though, I can’t quite control what I end up feeling interested in, what my next obsession becomes. I’ve never been great at contributing to open source, I’ve always much preferred creating things that belong to me. I do love the idea of open source, I’m just not very good at fitting that into how my brain works. So I build toy project after toy project, only occasionally sharing it publicly. In the cases where I have shared something, I’ve only ever made a minimal effort to “market” it. Like a lot of us, I don’t really enjoy distribution, and the goal isn't to get rich. I recognize it’s not ideal, it would be a lot of fun if other people find value in the things I build, and I care a lot about building good user experiences, good products. It would be incredible if something that I built took off.

My current passion project is an opinionated uptime monitoring service that uses multi-probe voting and retries before alerting, provides granular response time metrics, and has integrated status pages. It consists of an Elixir backend backed by PostgresQL and Clickhouse, with probes that are fully resilient to outages, write their own WALs, and can catch up once reconnected. And the biggest challenge: investing in making it properly reliable and for the operating cost per user to be low enough that I can offer this for free for the vast majority of users. It leads to a lot of interesting design decisions! If you do want to try it out, it's at https://larm.dev.

And it's so much fun to build! I'll be writing some posts about learnings from the project, and I'm working on splitting off some open source libraries. Using Phoenix Channels to connect a fleet of servers, distributing works across regions, not to mention getting some great use out of Clickhouse. If it sounds like an interesting service to you, take a look. I'm getting good use out of it, and more importantly, I'm having fun building it. Just like I did with that first website 20 years ago. So I’ll keep building things that are useful to me.

Looking forward to the next 20 years!
