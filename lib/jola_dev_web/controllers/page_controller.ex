defmodule JolaDevWeb.PageController do
  use JolaDevWeb, :controller

  def home(conn, _params) do
    recent_posts = Enum.take(JolaDev.Blog.all_posts(), 3)

    render(conn, :home,
      page_title: "Johanna Larsson — Software Engineer & Speaker",
      meta_description:
        "Johanna Larsson is a software engineer, engineering leader, writer, and speaker with many years of experience building products and leading teams.",
      og_image: JolaDev.OGImage.path_for("home"),
      recent_posts: recent_posts
    )
  end

  def about(conn, _params) do
    render(conn, :about,
      page_title: "About | jola.dev",
      meta_description:
        "About Johanna Larsson — software engineer, engineering leader, writer, and speaker with many years of experience.",
      og_image: JolaDev.OGImage.path_for("about"),
      page_type: :about
    )
  end

  def projects(conn, _params) do
    render(conn, :projects,
      page_title: "Projects | jola.dev",
      meta_description:
        "Open source projects by Johanna Larsson, including HexDiff, ElixirEvents, and more.",
      og_image: JolaDev.OGImage.path_for("projects")
    )
  end

  def talks(conn, _params) do
    render(conn, :talks,
      page_title: "Talks | jola.dev",
      meta_description:
        "Conference talks and presentations by Johanna Larsson on Elixir, distributed systems, and engineering leadership.",
      og_image: JolaDev.OGImage.path_for("talks")
    )
  end
end
