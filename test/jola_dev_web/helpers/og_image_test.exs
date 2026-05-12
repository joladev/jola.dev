defmodule JolaDevWeb.Helpers.OGImageTest do
  use JolaDevWeb.ConnCase, async: true

  @skip_plugs [
    JolaDevWeb.RssController,
    JolaDevWeb.SitemapController,
    JolaDevWeb.LlmsController,
    Phoenix.LiveView.Plug,
    Phoenix.LiveDashboard.Assets
  ]

  test "every public page has a working OG image" do
    for route <- JolaDevWeb.Router.__routes__(),
        route.verb == :get,
        route.plug not in @skip_plugs do
      path = concrete_path(route.path)
      page = get(build_conn(), path)
      assert page.status == 200, "GET #{path} returned #{page.status}"

      og_url = og_image_url(page.resp_body, path)
      og_path = URI.parse(og_url).path
      og_conn = get(build_conn(), og_path)

      assert og_conn.status == 200,
             "page #{path} declares og:image #{og_url} but it returned #{og_conn.status}. " <>
               "Add a catalog entry for slug \"#{slug(og_path)}\"."
    end
  end

  defp og_image_url(body, path) do
    case body
         |> LazyHTML.from_document()
         |> LazyHTML.query("meta[property='og:image']")
         |> LazyHTML.attribute("content") do
      [url] -> url
      [] -> flunk("no og:image meta tag on #{path}")
      urls -> flunk("multiple og:image meta tags on #{path}: #{inspect(urls)}")
    end
  end

  defp concrete_path("/posts/:id"),
    do: "/posts/#{List.first(JolaDev.Blog.all_posts()).id}"

  defp concrete_path("/posts/tag/:tag"),
    do: "/posts/tag/#{List.first(JolaDev.Blog.all_tags())}"

  defp concrete_path(path), do: path

  defp slug("/images/og/" <> rest), do: String.replace_suffix(rest, ".png", "")
end
