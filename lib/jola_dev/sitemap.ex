defmodule JolaDev.Sitemap do
  @moduledoc """
  Generates XML sitemap for search engines.
  """

  alias JolaDev.Blog

  @host "https://jola.dev"

  def generate do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{generate_static_pages()}#{generate_blog_posts()}
    </urlset>
    """
  end

  defp generate_static_pages do
    pages = [
      %{loc: @host, changefreq: "monthly", priority: "1.0"},
      %{loc: "#{@host}/about", changefreq: "monthly", priority: "0.8"},
      %{loc: "#{@host}/projects", changefreq: "weekly", priority: "0.9"},
      %{loc: "#{@host}/talks", changefreq: "monthly", priority: "0.7"},
      %{loc: "#{@host}/posts", changefreq: "weekly", priority: "0.9"}
    ]

    Enum.map_join(pages, "\n", &url_entry/1)
  end

  defp generate_blog_posts do
    Blog.all_posts()
    |> Enum.map(fn post ->
      %{
        loc: "#{@host}/posts/#{post.id}",
        lastmod: Date.to_iso8601(post.date),
        changefreq: "monthly",
        priority: "0.8"
      }
    end)
    |> Enum.map_join("\n", &url_entry/1)
  end

  defp url_entry(params) do
    """
      <url>
        <loc>#{params.loc}</loc>
        #{if params[:lastmod], do: "<lastmod>#{params.lastmod}</lastmod>", else: ""}
        <changefreq>#{params.changefreq}</changefreq>
        <priority>#{params.priority}</priority>
      </url>
    """
  end
end
