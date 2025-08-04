%{
  title: "Elixir String Processing Optimization",
  author: "Johanna Larsson",
  tags: ~w(elixir performance),
  description: "This post was inspired by a thread I participated in on the Elixir forum"
}
---
*Update: Since writing this post I’ve learned a lot. Check the very bottom of the article for some errata.*

This post was inspired by a thread I participated in on the [Elixir forum](https://elixirforum.com/t/erlang-elixir-string-performance-can-this-be-improved). The original post pointed to an article that compared a series of scripts implementing the same functionality, basically pretty-printing a sorted word count. The author of the post on the forum also provided an Elixir version, which was underperforming compared to the other scripts.

Now before you question the point of this. Yes, you’re right, Elixir is probably not the way to go for writing efficient string processing scripts. Not only does the VM start up a bit slower than Ruby or Python, it just isn’t designed or developed for this. But that doesn’t explain such a large difference in execution time.

To set the stage, here are the [original article’s benchmark results](http://ptrace.fefe.de/wp/timings2019.txt). Take a look if you’re curious, you can also look at the [implementations](http://ptrace.fefe.de/wp/), but some stand out to me as extra relevant. I’ve included the time the forum post author reported their implementation taking.

* C: 3.74s
* Ruby: 36.79s
* Elixir: 140s

Let’s just look at C as the baseline, that’s “ideal” speed, and Ruby comes in at an order of magnitude slower, which seems reasonable. But it took the Elixir script a whopping 37x as long to finish as the C version and almost 4 times longer than the Ruby. There has to be something we can do.

TLDR: Just so you don’t have to scroll to the end, the final version finishes in 13 seconds, over 10 times faster. But several tradeoffs are made to get there.

## Using ETS for fast mutable state

Let’s start by taking a look at the Elixir code

```elixir
IO.stream(:stdio, :line)
|> Stream.flat_map(&String.split/1)
|> Enum.reduce(%{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
|> Enum.sort(fn {_, a}, {_, b} -> b < a end)
|> Enum.each(fn {word, count} ->
  IO.puts(String.pad_leading(Integer.to_string(count), 8) <> " " <> word)
end)
```

This is perfectly reasonable Elixir, but it falls into a few performance traps. Running on my machine it took about 120 seconds. I’m going to walk through the steps I took towards writing a faster version.

Let’s start with something that makes perfect sense in most languages, and in most use cases in Elixir as well, but will turn out to be a huge performance issue here: the `Map`. Elixir maps are super useful and practical and will work for you most of the time, but unlike similar data structures in many other languages, the Elixir ones are immutable. Immutable data structures are amazing for a lot of reasons but in this script, we’re hitting some limitations. Basically, even with efficient structural sharing making sure we’re not blowing through the roof in memory use, we’re creating a new `Map` for every word and we’ve got 41,616,111 words in this input.

Fortunately, Elixir and Erlang have a solution for this: ETS. In the words of the [Erlang documentation](http://erlang.org/doc/man/ets.html):

> This module is an interface to the Erlang built-in term storage BIFs. These provide the ability to store very large quantities of data in an Erlang runtime system and to have constant access time to the data.

So here we have something that acts a little bit more like a mutable hash map. There are lots of other reasons why ETS is much cooler than a plan hash map, but I’ll leave that to a future article. For now, let’s just pretend that it’s a hash map.

It’s started with `:ets.new(:table_name, options)`. You can insert data with `:ets.insert` and read with `:ets.lookup`, but the two operations we’re interested in are `:ets.update_counter` and `:ets.match_object`. Here’s what it looks like if we replace the map with an ETS table.

```elixir
table = :ets.new(:words, [])

IO.stream(:stdio, :line)
|> Stream.flat_map(&String.split/1)
|> Enum.each(fn word -> :ets.update_counter(table, word, {2, 1}, {word, 0}) end)

:ets.tab2list(table)
|> Enum.sort(fn {_, a}, {_, b} -> b < a end)
|> Enum.each(fn {word, count} ->
  IO.puts(String.pad_leading(Integer.to_string(count), 8) <> " " <> word)
end)
```

The logic is fairly similar, except now we create a table and we need a separate step to read the table. Some `:ets` functions are a bit obscure but again, that’s a different article.

So what’s the verdict? Running this on my machine netted a whopping 3x speed up! From 120s to 40s, not too shabby, and we’re closing in on the ruby implementation. But there’s still lots of room for improvement.

## Elixir IO

First of all, none of the words in the data we’re working on is unicode, so we can drop the extra overhead that handling it involves. This means switching from `IO.stream/2` to `IO.binstream/2`. This netted a speedup of ~4s. Elixir mostly defaults to unicode support (regexes is a notable exception) which “just works”, but is not great for benchmarks.

Another improvement we can make in the area of IO is the last step, where it prints all the lines. This is basically creating and writing a huge number of strings to stdout. One of the issues of concatenating strings is that you’re creating more strings than you might expect. `"a" <> "b" <> "c"` creates 5 strings. Can you see why? Apart from the 3 string literals, you also get the result from the first concatenation and the result from the second concatenation. Out of the 5 strings that expression creates only 1 is actually kept around, the rest is “garbage”. Many languages, like Java and JavaScript (V8, etc) optimize this type of string concatenation to avoid creating the intermediate strings and only builds the string when it’s needed. But we can do that in Elixir/Erlang too! It’s called iolists. Here’s what it looks like:

Compare the last line of the original version

```elixir
|> Enum.each(fn {word, count} ->
  IO.puts(String.pad_leading(Integer.to_string(count), 8) <> " " <> word)
end)
```

with building an iolist before printing

```elixir
|> Enum.map(fn {word, count} ->
  [String.pad_leading(Integer.to_string(count), 8), " ", word, "\n"] end)
|> IO.binwrite()
```

Instead of concatenating and printing line by line, it produces one nested list of strings and pipes it to `IO.puts` for printing. This is arguably less convenient, needing to know about iolists in Elixir, while JS and Java just handle it for you, but it’s a matter of philosophy. If Elixir was designed primarily for writing text processing scripts, it would probably look very different. Most applications don’t have to worry about iolists, but if you need to squeeze every last bit of performance out of your app, it’s a neat tool to keep in your toolbox.

Result? Another ~3s. No huge gains here, but we’re making improvements. We’re now clocking in at 34s.

## String.split/1, String.split/2

This is an incredibly versatile function that can be tuned to your needs. Just calling it with a single input splits it on all whitespace.

```elixir
["some", "words", "here"] = String.split("\tsome \n words    here\r")
```

But matching all kinds of whitespace is a lot of overhead when we only need to care about two. The lines we get from `IO.binstream` look a little something like this `"word1 word2 word3\n"`.

`String.split/2` accepts pattern or a regex as it’s second argument, so just to compare I tried a regex that matches space and new line: `&String.split(&1, ~r"[ \n]")`. This ran 40 seconds slower than the previous `&String.split(&1)`. So what’s the deal, how is `String.split/1` faster than our regex? Well, internally `String.split/1` is not implemented with regexes but with patterns. A pattern can be defined on the fly as a simple string, which would look like this for splitting on commas: `&String.split(&1, ",")`. You can even use multiple strings, like `[" ","\n"]`. This is what we need because there are both spaces and new lines in our line, `IO.binstream` doesn’t strip the new line characters. This looks like this `&String.split(&1, [" ", "\n"])` and is an incredible 40% speedup vs `&String.split(&1)` for this script and input.

Finally, you can optimize your pattern by “compiling” it, using `:binary.compile_pattern`. Note that this compilation, maybe unexpectedly, happens at run time. Let’s take a look at our code with the compiled pattern.

```elixir
table = :ets.new(:words, [])
pattern = :binary.compile_pattern([" ", "\n"])

IO.binstream(:stdio, :line)
|> Stream.flat_map(&String.split(&1, pattern))
|> Enum.each(fn word -> :ets.update_counter(table, word, {2, 1}, {word, 0}) end)

:ets.tab2list(table)
|> Enum.sort(fn {_, a}, {_, b} -> b < a end)
|> Enum.map(fn {word, count} ->
  [String.pad_leading(Integer.to_string(count), 8), " ", word, "\n"]
end)
|> IO.binwrite()
```

Finishes in 19s on my machine, close to twice as fast as the Ruby version. We’ve made some huge improvements, combined with some tradeoffs. Notably, we lost UTF-8 support. The code is also less straightforward than the original. Remember that faster code is not necessarily better code. In this case, we had a problem, it was unreasonable for the script to be that slow. We’ve improved speed, but we’ve added complexity. It’s not unreadable, but there’s some cognitive overhead in using ETS over a `Map`, and pre-compiling a binary match pattern. Let’s take a look at another tradeoff we can make.

## Memory vs CPU

This version of the code contains a memory optimization, it reads from a stream of text line by line, meaning each line after processing is free to be garbage collected. This reduces the total required memory to run the script, but it’s also a lot less CPU efficient. What if we load the entire string into memory first and run `String.split` only once?

```elixir
IO.binstream(:stdio, 102400)
|> Enum.to_list()
|> :binary.list_to_bin()
|> String.split(pattern)
```

I didn’t spend a lot of time tweaking the chunk size, but basically, you want to read as much as possible per chunk and then build one string. This brings the `user` part of the execution time down to under 11 seconds, but increases `system` time a bit, giving an actual run time of 13 seconds.

## Conclusion

Here’s the final version of our optimized script

```elixir
table = :ets.new(:words, [])
pattern = :binary.compile_pattern([" ", "\n"])

IO.binstream(:stdio, 102400)
|> Enum.to_list()
|> :binary.list_to_bin()
|> String.split(pattern)
|> Enum.each(fn word -> :ets.update_counter(table, word, {2, 1}, {word, 0}) end)

:ets.tab2list(table)
|> Enum.sort(fn {_, a}, {_, b} -> b < a end)
|> Enum.map(fn {word, count} ->
  [String.pad_leading(Integer.to_string(count), 8), " ", word, "\n"]
end)
|> IO.binwrite()
```

I feel like this is a good example of how some knowledge about Elixir/Erlang lets you optimize your code when needed. Any article like this needs a disclaimer about premature optimization, most of these techniques don’t make sense as general use tools. Never try to optimize blindly. The biggest benefit of using Elixir in the first place is that it enables you to write code that makes sense, is maintainable and stable. It’s a platform that enables you to define complex and durable applications while writing code that is readable and concise. But when you’re hitting performance bottlenecks it’s worth having these tricks up your sleeve.

## Bonus round: Flow

Tools like Flow lets you parallelize certain tasks with little to no effort. In fact, if you follow that link, the first code example given is actually close to exactly what we’re doing here, counting words in some input. Let’s use that example and apply the adjustments described in this article.

```elixir
table = :ets.new(:words, [{:write_concurrency, true}, :public])
space = :binary.compile_pattern([" ", "\n"])

IO.binstream(:stdio, :line)
|> Flow.from_enumerable()
|> Flow.flat_map(&String.split(&1, space))
|> Flow.each(fn word ->
  :ets.update_counter(table, word, {2, 1}, {word, 0})
end)
|> Flow.run()

:ets.tab2list(table)
|> Enum.sort(fn {_, a}, {_, b} -> b < a end)
|> Enum.map(fn {word, count} ->
  [String.pad_leading(Integer.to_string(count), 8), " ", word, "\n"]
end)
|> IO.binwrite()
```

Not much changed really, we tell Flow to use the stream from `IO.binstream`, use the specialized versions of `flat_map` and `each`, and finally tell Flow to run. In this version, loading the entire input and splitting only once is slower than spreading the work over the cores. You might also have noticed that I’m passing some options to `:ets.new`. Because Flow will parallelize the calls to `:ets.update_counter` across multiple processes we need to tell `:ets` to optimize concurrent writes, and set the access level to `:public` to allow other processes writing to our table.

Our code still reads mostly the same, but splitting and updating ETS will now run in parallel over all available cores and brings us down to a cool 12s while preserving that reduces memory use (what won’t be cool is your computer when you’re using all your cores). Note that at this point we’re fighting the OS and other running apps for the cores, so actual run time can vary a lot. Because this version requires dependencies and only runs 1 second faster while using all available cores, I don’t consider it a better version than the “single threaded” one. But because of its more memory efficient input loading, it should scale better with larger inputs.

## Bonus bonus round: Faster Ruby

My colleague [Maciej Mensfeld](https://mensfeld.pl/) took a look at the Ruby version and the results and gave me this

```elixir
#!/usr/bin/ruby

GC.disable

counts = Hash.new { 0 }

str = ''

STDIN.each_line do |line|
  str << line
end

str
  .split(' ')
  .each { |word| counts[word] += 1 }

counts
  .sort { |a, b| b[1] <=> a[1] }
  .each { |i| printf "  %4u => %s\n", i[1], i[0] }
```

which is single threaded and runs in 13 seconds. Huge difference from the 37s one from the original article. Note that this makes a similar tradeoff to the last improvement of the Elixir code, it loads the entire input before splitting.

## Notes on ETS

`:ets.match_object(table, {:"$0", :"$1"})` was faster than `:ets.tab2list/1` in my experiments, but I wouldn’t rely on it as a universal truth. The latter is also a lot easier to read. EDIT: with further testing I wasn’t able to replicate this, and I updated my snippets to use `:ets.tab2list/1`

Passing the `ets` table by reference was significantly faster than using a named table.

## Errata

Updated the article to use `:ets.tab2list/1` over `:ets.match_object(table, {:"$0", :"$1"})` since more testing showed it wasn’t faster, and it’s harder to read.
