defmodule JolaDevWeb.BlogController do
  use JolaDevWeb, :controller

  def index(conn, _params) do
    posts = JolaDev.Blog.all_posts()
    render(conn, :index, posts: posts, page_title: "jola.dev - Posts")
  end

  def show(conn, params) do
    if post = JolaDev.Blog.find_by_id(params["id"]) do
      render(conn, :show, post: post, page_title: "jola.dev - #{post.title}")
    else
      conn
      |> put_status(404)
      |> put_view(html: JolaDevWeb.ErrorHTML)
      |> render("404.html")
    end
  end
end
