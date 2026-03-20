defmodule JolaDevWeb.BlogController do
  use JolaDevWeb, :controller

  def index(conn, _params) do
    posts = JolaDev.Blog.all_posts()

    render(conn, :index,
      posts: posts,
      page_title: "Blog | jola.dev",
      meta_description:
        "Blog posts by Johanna Larsson on software engineering, Elixir, and engineering leadership."
    )
  end

  def show(conn, params) do
    if post = JolaDev.Blog.find_by_id(params["id"]) do
      render(conn, :show,
        post: post,
        page_title: "#{post.title} | jola.dev",
        meta_description: post.description
      )
    else
      conn
      |> put_status(404)
      |> put_view(html: JolaDevWeb.ErrorHTML)
      |> render("404.html")
    end
  end
end
