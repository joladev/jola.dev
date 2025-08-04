defmodule JolaDevWeb.SitemapController do
  use JolaDevWeb, :controller

  def index(conn, _params) do
    sitemap = JolaDev.Sitemap.generate()

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, sitemap)
  end
end
