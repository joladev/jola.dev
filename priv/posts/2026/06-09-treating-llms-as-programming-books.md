%{
  title: "Treating LLMs as programming books",
  author: "Johanna Larsson",
  tags: ~w(llm agent coding engineering),
  description: "Thoughts on an approach for using LLMs effectively for coding without losing engagement and cognitive effort."
}
---

LLMs can often perform localized miracles, quickly building something that works, or at least gives the appearance of working. When an LLM does something that you’re not an expert on, it’s like magic. It can write Terraform HCL, knows every single bash tool invocation, tackle your Tailwind issues (after a few false starts), and debug your Kubernetes cluster, all without breaking a sweat. Of course, the more you know about a topic the less impressive it is. It often makes things more complicated than they need to be, it’s rarely elegant. Still, if you care more about building something and getting it in front of users than you do meticulously crafting each line of code, you can produce something really fast.

Working with LLMs over a longer period of time, your standards for acceptable code change. It’s not necessarily that they get worse, but the pattern I’ve seen is caring less and less about each individual line of code, and the focus during review shifting more towards overall design and patterns. LLMs are great at encouraging you to trust them to do work for you, and they’ll always attempt to take over more and more of your daily workflow. Over time you start relying on them for every step of the process, researching, designing, implementing, reviewing, even writing the commit messages and creating PRs.

Eventually you realize you’ve outsourced all of your cognitive work. It might be fine for a while. But if you’re like me, you’ll eventually start worrying about what this is doing to your ability to design and write code independently. Not just that, but what it’s doing to your very identity and self-image.

I’ve read a bunch of articles recently, on the topic of how to “safely” use LLMs while still staying engaged mentally, and honestly I didn’t find any of them very compelling. They all just boiled down to: stay focused.

I recently had a few weeks off work and I used them to reconnect with coding. I avoided using any of the SOTA models, although I have been playing around with running models locally as well as some larger open weight models through OpenRouter and Mistral. While doing that I’ve started playing around with a different way of LLM-assisted coding: treating them like on-demand programming books.

## Typing the code snippets

Two decades ago, when I started learning programming, I would go to the bookstore and look for interesting looking books. I got some on PHP, Linux, Apache, HTML/CSS/JS, and more. Every book was a wonder. I’d bring it home and sit down in front of the computer and I’d start typing.

Every single example in the book, I’d type it all by hand. What choice did I have! There was no digital version, nothing to copy paste. I typed for hours and hours until my fingers hurt. Every chapter I finished was a new reward, some new accomplishment.

There’s something magical about typing out code. It doesn’t even seem to matter that it’s not your code, not your design. It’s like while you type, some magic is happening deep down in your brain, where it’s internalizing the structure and design, until you’re able to re-create it on command.

It’s a tried and tested way of learning how to program. You just need books and computer to type on! And that’s where the LLMs come in. Ethical considerations aside (and they are serious ethical considerations, let’s not pretend), LLMs have the ability to produce a near infinite number of volumes of generated programming literature, code examples included. You just need to ask.

## A suggested approach

The workflow is similar to the standard agentic one, you start off by researching and discussing until you find an approach you like, with a plan that makes sense to you. You probably still want to run it from your given codebase, rather than as a chatbot on a webpage, so it can read and analyze the local code easily. The big distinction here though is that you make the instructions clear: the LLM is not making any edits. Not a single one.

Once you have the plan ready, it’s time to get to work. Have the bot produce code examples and suggestions from the plan you agreed on, snippet by snippet, and type it out yourself.

Now don’t get surprised if this *hurts*. You’re going to be doing a lot of typing. A lot a lot. You better be using a good keyboard.

But the pain is valuable. The pain teaches you the value of clear and concise code. The pain teaches you not to write unnecessary tests. The sheer effort involved will keep you focused on the real goals. All the while, your brain will be processing in the background, and you will be engaged in a way you can never accomplish with a hands off agentic approach.

*You will learn so much*. Stick with it, it’s worth it.

## Why is this better?

Typing engages your brain in a different way. It’s just the way it is. There are studies that show that writing by hand is even better, but that’s an awkward option for executing code. So typing it is.

You just can’t avoid being engaged as you read and then type line after line of code. You’ll soon have a moment where you realize that the plan that previously looked so good, actually had flaws. As you type, as you’re processing in the background, you’re going to have epiphanies. You’re going to find bugs, and issues, and unexpected drawbacks of your approach. Tackle them head on. Engage and find solutions. And then get back to typing again.

Typing keeps you in the loop. You are the loop. You own every single line of code you’re producing, in a way that you never could have if Claude or Codex wrote it for you. You’re going to feel real ownership of the code. Of every line of code. Of every technical decision.

Oh, my god it’s so much work. But worth it.

As you’re doing that, try to spend less and less time typing the example out exactly as it is in the terminal and start trying to read it first and then recreate it from memory. It’s ok if it doesn’t work at first, go back to the code snippets as many times as you need. But practice that ability of looking at a piece of code and grasping its shape, to the point where you’re able to recreate it. Maybe slightly different than the original, but accomplishing the same thing.

## Is it good though?

This is probably still not the ideal way to write code, at least not for many of us. You might not feel as productive as you do when you’re juggling agentic sessions and mass producing code. You’re still incredibly dependent on LLMs, although to be fair you can probably do alright with a dumber model, maybe even something that runs on your own computer. Maybe you can opt for a more ethical option, amongst the unethical options.

I think we’re all still figuring out how to deal with the changes that this technology has brought the world. I think we should do our best to find a path forward, whether that means avoiding it completely, trying to use it in a way that keeps our brains engaged, or, I guess, going all in and accepting that our job is now just feeding ideas into the machine until we burn out.
