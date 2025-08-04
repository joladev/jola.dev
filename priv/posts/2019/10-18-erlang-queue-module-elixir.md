%{
  title: "The Erlang :queue module in Elixir",
  author: "Johanna Larsson",
  tags: ~w(queue erlang elixir),
  description: "Elixir doesn’t provide its own data structures, instead, it uses the ones provided by Erlang"
}
---
Elixir doesn’t provide its own data structures, instead, it uses the ones provided by Erlang. Many of them are wrapped by Elixir modules and have shorthand syntax, to make them easier to work with. You’ve seen `[]`, `{}`, and `%{}`, and the modules `List`, `Tuple`, and `Map`. Elixir also exposes “structs”, which are maps with special behaviors associated with them. Some structs are treated as opaque, like `MapSet`, with its own set of functions to interact with it. But Erlang has a few more data types that, because they’re not wrapped in Elixir, you might not have been introduced to yet. This article is about the one I’ve had the most use of, `:queue`.

Erlang queues are similar to lists but double-ended, meaning you can efficiently insert items to both the front and the rear of it. It is also known as a “first in first out”, or FIFO, data structure. The Erlang documentation describes it:

> Queues are double-ended. The mental picture of a queue is a line of people (items) waiting for their turn. The queue front is the end with the item that has waited the longest. The queue rear is the end an item enters when it starts to wait. If instead using the mental picture of a list, the front is called head and the rear is called tail.

A common use case is where you want to temporarily store items and eventually take them back out in the order that you put them in.

Using them can feel a bit awkward, partly because Erlang orders arguments differently than Elixir, and partly because the internal representation of queues is exposed. Note that the docs clearly state that you should treat it as an opaque type.

Here’s some examples of how to use it

```elixir
iex(38)> q = :queue.new()
{[], []}
iex(33)> q = :queue.in("a", q)
{["a"], []}
iex(34)> q = :queue.in("b", q)
{["b"], ["a"]}
iex(35)> q = :queue.in("c", q)
{["c", "b"], ["a"]}
```

When getting items back out you need to keep track of both the item and the queue.

```elixir
iex(36)> {{:value, value3}, q} = :queue.out(q)
{{:value, "a"}, {["c"], ["b"]}}
iex(37)> {{:value, value2}, q} = :queue.out(q)
{{:value, "b"}, {[], ["c"]}}
iex(37)> {{:value, value3}, q} = :queue.out(q)
{{:value, "c"}, {[], []}}
```

If the queue is empty you get the `:empty` atom instead.

```elixir
iex(39)> :queue.out(q)
{:empty, {[], []}}
```

One thing to note about queues is that they don’t keep track of their length themselves, so `:queue.len/1` has to traverse the entirety of the queue. If you’re working with very large queues and frequently need to check the size, consider keeping track of it separately, or creating your own wrapped queue module.

[Check out the documentation for more information and functions.](http://erlang.org/doc/man/queue.html)
