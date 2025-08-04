defmodule JolaDevWeb.RssController do
  use JolaDevWeb, :controller

  def index(conn, _params) do
    posts = JolaDev.Blog.all_posts()

    conn
    |> put_resp_content_type("application/rss+xml")
    |> render(:index, posts: posts)
  end
end
