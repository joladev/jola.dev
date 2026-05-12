defmodule JolaDev.OGImage.Catalog do
  @moduledoc """
  This module owns the content used to render the OG images,
  including the full list of matching slugs.
  """

  alias JolaDev.Blog

  @static_content %{
    "home" =>
      {"Johanna Larsson",
       "Software engineer, engineering leader, writer, and speaker with many years of experience building products and leading teams."},
    "about" =>
      {"About",
       "About Johanna Larsson: software engineer, engineering leader, writer, and speaker with many years of experience."},
    "projects" =>
      {"Projects",
       "Open source projects by Johanna Larsson, including HexDiff, ElixirEvents, and more."},
    "talks" =>
      {"Talks",
       "Conference talks and presentations by Johanna Larsson on Elixir, distributed systems, and engineering leadership."},
    "posts" =>
      {"Blog",
       "Blog posts by Johanna Larsson on software engineering, Elixir, and engineering leadership."}
  }

  def content_for(slug) when is_map_key(@static_content, slug),
    do: Map.fetch!(@static_content, slug)

  def content_for("posts/tag/" <> tag) do
    if tag in Blog.all_tags() do
      {~s(Posts tagged "#{tag}"), "Blog posts by Johanna Larsson tagged with #{tag}."}
    else
      :error
    end
  end

  def content_for("posts/" <> id) do
    case Blog.find_by_id(id) do
      nil -> :error
      post -> {post.title, post.description}
    end
  end

  def content_for(_), do: :error

  def all_slugs do
    static = Map.keys(@static_content)
    posts = Enum.map(Blog.all_posts(), &"posts/#{&1.id}")
    tags = Enum.map(Blog.all_tags(), &"posts/tag/#{&1}")
    static ++ posts ++ tags
  end
end
