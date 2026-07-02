defmodule JolaDev.Atproto do
  @moduledoc """
  Maps blog posts to standard.site records and builds the AT-URIs used
  for verification (the .well-known endpoint and per-post <link> tags).
  """

  alias JolaDev.Atproto.Document
  alias JolaDev.Atproto.Publication
  alias JolaDev.Atproto.TID
  alias JolaDev.Blog.Post

  # Retrieved by using JolaDev.Atproto.Client.resolve_handle
  @did "did:plc:bvraa6gajy4tfr3eh2sisdkr"
  @publication_rkey "3mope7jyypk22"
  @url "https://jola.dev"

  def publication_uri, do: "at://#{@did}/site.standard.publication/#{@publication_rkey}"
  def publication_rkey, do: @publication_rkey

  def document_uri(slug, published_at) do
    rkey = TID.deterministic(slug, published_at)
    "at://#{@did}/site.standard.document/#{rkey}"
  end

  def publication do
    %Publication{
      name: "jola.dev",
      url: @url,
      description: "Johanna Larsson's blog",
      icon:
        {File.read!(Application.app_dir(:jola_dev, "priv/static/images/logo.png")), "image/png"},
      preferences: %{
        showInDiscover: true
      }
    }
  end

  def document(%Post{} = post) do
    {:ok, cover_image} = JolaDev.OGImage.image_for("posts/#{post.id}")
    rkey = TID.deterministic(post.id, post.date)

    %Document{
      rkey: rkey,
      site: publication_uri(),
      title: post.title,
      path: "/posts/#{post.id}",
      published_at: post.date,
      updated_at: post.last_modified,
      description: post.description,
      text_content: post.text_content,
      tags: post.tags,
      cover_image: {cover_image, "image/png"}
    }
  end
end
