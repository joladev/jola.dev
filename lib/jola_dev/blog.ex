defmodule JolaDev.Blog do
  @moduledoc """
  The Blog context for managing blog posts.

  Uses NimblePublisher to parse and serve markdown blog posts from the priv/posts directory.
  """

  use NimblePublisher,
    build: JolaDev.Blog.Post,
    from: Application.app_dir(:jola_dev, "priv/posts/**/*.md"),
    as: :posts,
    html_converter: JolaDev.Blog.MarkdownConverter,
    highlighters: [:makeup_elixir],
    earmark_options:
      Earmark.Options.make_options!(
        registered_processors: [
          Earmark.TagSpecificProcessors.new([
            {"a", &Earmark.AstTools.merge_atts_in_node(&1, class: "underline")},
            {"h1", &Earmark.AstTools.merge_atts_in_node(&1, class: "text-3xl py-4")},
            {"h2", &Earmark.AstTools.merge_atts_in_node(&1, class: "text-2xl py-4")},
            {"h3", &Earmark.AstTools.merge_atts_in_node(&1, class: "text-xl py-4")},
            {"p", &Earmark.AstTools.merge_atts_in_node(&1, class: "text-md pb-4")},
            {"code", &Earmark.AstTools.merge_atts_in_node(&1, class: "")},
            {"pre",
             &Earmark.AstTools.merge_atts_in_node(&1,
               class: "mb-4 p-1 py-4 overflow-x-scroll border-y"
             )},
            {"ol", &Earmark.AstTools.merge_atts_in_node(&1, class: "list-decimal")},
            {"ul", &Earmark.AstTools.merge_atts_in_node(&1, class: "list-disc pb-4")},
            {"blockquote",
             &Earmark.AstTools.merge_atts_in_node(&1,
               class: "pl-4 border-l-2 mb-4 border-purple-700"
             )}
          ])
        ]
      )

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

  def find_by_id(id) do
    Enum.find(all_posts(), fn post -> post.id == id end)
  end

  def titles do
    Enum.map(all_posts(), & &1.title)
  end

  def ids do
    Enum.map(all_posts(), & &1.id)
  end
end
