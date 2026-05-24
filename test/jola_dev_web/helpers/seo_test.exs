defmodule JolaDevWeb.Helpers.SEOTest do
  use JolaDevWeb.ConnCase, async: true

  alias JolaDevWeb.Helpers.SEO

  describe "json_ld/1" do
    test "includes WebSite schema on all pages", %{conn: conn} do
      conn = get(conn, ~p"/")
      schemas = SEO.json_ld(conn)

      website = Enum.find(schemas, &(&1["@type"] == "WebSite"))
      assert website["name"] == "jola.dev"
      assert website["url"] == "https://jola.dev"
      refute Map.has_key?(website, "author")
    end

    test "includes Person schema on all pages", %{conn: conn} do
      for path <- [~p"/", ~p"/posts", ~p"/projects", ~p"/talks", ~p"/about"] do
        schemas = SEO.json_ld(get(conn, path))
        person = Enum.find(schemas, &(&1["@type"] == "Person"))

        assert person["@id"] == "https://jola.dev/#person", "missing Person on #{path}"
        assert person["name"] == "Johanna Larsson"
        assert is_list(person["sameAs"])
      end
    end

    test "includes BlogPosting schema on blog post pages", %{conn: conn} do
      post = List.first(JolaDev.Blog.all_posts())
      conn = get(conn, ~p"/posts/#{post.id}")
      schemas = SEO.json_ld(conn)

      blog_posting = Enum.find(schemas, &(&1["@type"] == "BlogPosting"))
      assert blog_posting["headline"] == post.title
      assert blog_posting["description"] == post.description
      assert blog_posting["datePublished"] == Date.to_iso8601(post.date)
      assert blog_posting["dateModified"] == Date.to_iso8601(post.last_modified)
      assert blog_posting["inLanguage"] == "en"
      assert blog_posting["url"] == "https://jola.dev/posts/#{post.id}"
      assert blog_posting["image"] == "https://jola.dev/images/og/posts/#{post.id}.png"
      assert blog_posting["author"]["@type"] == "Person"
      assert blog_posting["keywords"] == post.tags
    end

    test "includes ProfilePage schema on about page referencing the Person", %{conn: conn} do
      conn = get(conn, ~p"/about")
      schemas = SEO.json_ld(conn)

      profile = Enum.find(schemas, &(&1["@type"] == "ProfilePage"))
      assert profile["mainEntity"] == %{"@id" => "https://jola.dev/#person"}
    end

    test "does not include BlogPosting on non-post pages", %{conn: conn} do
      conn = get(conn, ~p"/projects")
      schemas = SEO.json_ld(conn)

      refute Enum.any?(schemas, &(&1["@type"] == "BlogPosting"))
    end

    test "includes Blog schema with blogPost list on /posts", %{conn: conn} do
      conn = get(conn, ~p"/posts")
      schemas = SEO.json_ld(conn)

      blog = Enum.find(schemas, &(&1["@type"] == "Blog"))
      assert blog["@id"] == "https://jola.dev/posts#blog"
      assert blog["url"] == "https://jola.dev/posts"
      assert blog["author"] == %{"@id" => "https://jola.dev/#person"}
      assert is_list(blog["blogPost"])
      assert length(blog["blogPost"]) == length(JolaDev.Blog.all_posts())

      first = hd(blog["blogPost"])
      assert first["@type"] == "BlogPosting"
      assert is_binary(first["headline"])
      assert String.starts_with?(first["url"], "https://jola.dev/posts/")
      assert first["author"] == %{"@id" => "https://jola.dev/#person"}
    end

    test "does not include Blog schema on tag pages", %{conn: conn} do
      conn = get(conn, ~p"/posts/tag/elixir")
      schemas = SEO.json_ld(conn)

      refute Enum.any?(schemas, &(&1["@type"] == "Blog"))
    end

    test "omits BreadcrumbList on the home page", %{conn: conn} do
      conn = get(conn, ~p"/")
      schemas = SEO.json_ld(conn)

      refute Enum.any?(schemas, &(&1["@type"] == "BreadcrumbList"))
    end

    test "includes BreadcrumbList on /about", %{conn: conn} do
      conn = get(conn, ~p"/about")
      schemas = SEO.json_ld(conn)

      breadcrumb = Enum.find(schemas, &(&1["@type"] == "BreadcrumbList"))

      assert breadcrumb["itemListElement"] == [
               %{
                 "@type" => "ListItem",
                 "position" => 1,
                 "name" => "Home",
                 "item" => "https://jola.dev/"
               },
               %{
                 "@type" => "ListItem",
                 "position" => 2,
                 "name" => "About",
                 "item" => "https://jola.dev/about"
               }
             ]
    end

    test "includes BreadcrumbList with post title on post pages", %{conn: conn} do
      post = List.first(JolaDev.Blog.all_posts())
      conn = get(conn, ~p"/posts/#{post.id}")
      schemas = SEO.json_ld(conn)

      breadcrumb = Enum.find(schemas, &(&1["@type"] == "BreadcrumbList"))
      items = breadcrumb["itemListElement"]

      assert length(items) == 3
      assert List.last(items)["name"] == post.title
      assert List.last(items)["item"] == "https://jola.dev/posts/#{post.id}"
    end

    test "includes BreadcrumbList with tag on tag pages", %{conn: conn} do
      tag = "elixir"
      conn = get(conn, ~p"/posts/tag/#{tag}")
      schemas = SEO.json_ld(conn)

      breadcrumb = Enum.find(schemas, &(&1["@type"] == "BreadcrumbList"))
      items = breadcrumb["itemListElement"]

      assert length(items) == 3
      assert List.last(items)["name"] == tag
      assert List.last(items)["item"] == "https://jola.dev/posts/tag/#{tag}"
    end
  end
end
