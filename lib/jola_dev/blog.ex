defmodule JolaDev.Blog do
  @moduledoc """
  The Blog context for managing blog posts.

  Uses NimblePublisher to parse and serve markdown blog posts from the priv/posts directory.
  """

  use NimblePublisher,
    build: JolaDev.Blog.Post,
    from: Application.app_dir(:jola_dev, "priv/posts/**/*.md"),
    as: :posts,
    html_converter: JolaDev.Blog.MarkdownConverter

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @posts
        |> Enum.flat_map(& &1.tags)
        |> Enum.uniq()
        |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts
  def all_tags, do: @tags

  def posts_by_tag(tag) do
    Enum.filter(all_posts(), fn post -> tag in post.tags end)
  end

  def find_by_id(id) do
    Enum.find(all_posts(), fn post -> post.id == id end)
  end

  def titles do
    Enum.map(all_posts(), & &1.title)
  end

  def ids do
    Enum.map(all_posts(), & &1.id)
  end

  def recent_posts(%JolaDev.Blog.Post{id: id}, limit \\ 3) do
    all_posts()
    |> Enum.reject(&(&1.id == id))
    |> Enum.sort_by(& &1.date, {:desc, Date})
    |> Enum.take(limit)
  end

  def related_posts(%JolaDev.Blog.Post{id: id, tags: tags}, limit \\ 3) do
    all_posts()
    |> Enum.reject(&(&1.id == id))
    |> Enum.map(&{&1, Enum.count(&1.tags, fn t -> t in tags end)})
    |> Enum.sort_by(fn {p, _} -> p.date end, {:desc, Date})
    |> Enum.sort_by(fn {_, count} -> count end, :desc)
    |> Enum.take(limit)
    |> Enum.map(&elem(&1, 0))
  end
end
