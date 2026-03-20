defmodule JolaDevWeb.SEOTest do
  use JolaDevWeb.ConnCase, async: true

  describe "json_ld/1" do
    test "includes WebSite schema on all pages", %{conn: conn} do
      conn = get(conn, ~p"/")
      schemas = JolaDevWeb.SEO.json_ld(conn)

      website = Enum.find(schemas, &(&1["@type"] == "WebSite"))
      assert website["name"] == "jola.dev"
      assert website["url"] == "https://jola.dev"
    end

    test "includes BlogPosting schema on blog post pages", %{conn: conn} do
      post = List.first(JolaDev.Blog.all_posts())
      conn = get(conn, ~p"/posts/#{post.id}")
      schemas = JolaDevWeb.SEO.json_ld(conn)

      blog_posting = Enum.find(schemas, &(&1["@type"] == "BlogPosting"))
      assert blog_posting["headline"] == post.title
      assert blog_posting["description"] == post.description
      assert blog_posting["datePublished"] == Date.to_iso8601(post.date)
      assert blog_posting["author"]["@type"] == "Person"
      assert blog_posting["keywords"] == post.tags
    end

    test "includes ProfilePage schema on about page", %{conn: conn} do
      conn = get(conn, ~p"/about")
      schemas = JolaDevWeb.SEO.json_ld(conn)

      profile = Enum.find(schemas, &(&1["@type"] == "ProfilePage"))
      assert profile["mainEntity"]["@type"] == "Person"
      assert profile["mainEntity"]["name"] == "Johanna Larsson"
      assert is_list(profile["mainEntity"]["sameAs"])
    end

    test "does not include BlogPosting on non-post pages", %{conn: conn} do
      conn = get(conn, ~p"/projects")
      schemas = JolaDevWeb.SEO.json_ld(conn)

      refute Enum.any?(schemas, &(&1["@type"] == "BlogPosting"))
    end
  end
end
