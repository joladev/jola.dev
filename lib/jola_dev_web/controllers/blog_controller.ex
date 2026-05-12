defmodule JolaDevWeb.BlogController do
  use JolaDevWeb, :controller

  def index(conn, _params) do
    posts = JolaDev.Blog.all_posts()

    render(conn, :index,
      posts: posts,
      page_title: "Blog | jola.dev",
      meta_description:
        "Blog posts by Johanna Larsson on software engineering, Elixir, and engineering leadership.",
      og_image: JolaDev.OGImage.path_for("posts")
    )
  end

  def tag(conn, %{"tag" => tag}) do
    posts = JolaDev.Blog.posts_by_tag(tag)

    if posts == [] do
      conn
      |> put_status(404)
      |> put_view(html: JolaDevWeb.ErrorHTML)
      |> render("404.html")
    else
      render(conn, :tag,
        posts: posts,
        tag: tag,
        noindex: true,
        page_title: "Posts tagged \"#{tag}\" | jola.dev",
        meta_description: "Blog posts by Johanna Larsson tagged with #{tag}.",
        og_image: JolaDev.OGImage.path_for("posts/tag/#{tag}")
      )
    end
  end

  def show(conn, params) do
    if post = JolaDev.Blog.find_by_id(params["id"]) do
      render(conn, :show,
        post: post,
        related_posts: JolaDev.Blog.recent_posts(post),
        page_title: "#{post.title} | jola.dev",
        meta_description: post.description,
        og_image: JolaDev.OGImage.path_for("posts/#{post.id}")
      )
    else
      conn
      |> put_status(404)
      |> put_view(html: JolaDevWeb.ErrorHTML)
      |> render("404.html")
    end
  end
end
