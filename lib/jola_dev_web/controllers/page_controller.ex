defmodule JolaDevWeb.PageController do
  use JolaDevWeb, :controller

  def home(conn, _params) do
    recent_posts = Enum.take(JolaDev.Blog.all_posts(), 3)
    render(conn, :home, page_title: "jola.dev", recent_posts: recent_posts)
  end

  def about(conn, _params) do
    render(conn, :about, page_title: "jola.dev - About")
  end

  def projects(conn, _params) do
    render(conn, :projects, page_title: "jola.dev - Projects")
  end

  def talks(conn, _params) do
    render(conn, :talks, page_title: "jola.dev - Talks")
  end
end
