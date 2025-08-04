defmodule JolaDevWeb.RssControllerTest do
  use JolaDevWeb.ConnCase, async: true

  describe "index" do
    test "returns valid RSS feed", %{conn: conn} do
      conn = get(conn, ~p"/rss.xml")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/rss+xml; charset=utf-8"]

      body = response(conn, 200)

      # Check RSS structure
      assert body =~ ~r/<\?xml version="1.0" encoding="UTF-8"\?>/
      assert body =~ ~r/<rss version="2.0"/
      assert body =~ ~r/xmlns:content="http:\/\/purl\.org\/rss\/1\.0\/modules\/content\/"/
      assert body =~ ~r/<channel>/
      assert body =~ ~r/<title>jola.dev<\/title>/
      assert body =~ ~r/<description>Blog posts from jola.dev<\/description>/
      assert body =~ ~r/<language>en-us<\/language>/

      # Check that posts are included
      posts = JolaDev.Blog.all_posts()
      first_post = List.first(posts)

      assert body =~ ~r/<item>/
      assert body =~ first_post.title

      assert body =~
               ~r/<description><!\[CDATA\[#{Regex.escape(first_post.description)}\]\]><\/description>/

      assert body =~ ~r/<content:encoded><!\[CDATA\[.*\]\]><\/content:encoded>/s
      assert body =~ first_post.body
      assert body =~ ~r/<guid isPermaLink="true">/
      assert body =~ ~r/<pubDate>/
    end

    test "feed.xml returns same content as rss.xml", %{conn: conn} do
      rss_conn = get(conn, ~p"/rss.xml")
      feed_conn = get(conn, ~p"/feed.xml")

      assert response(rss_conn, 200) == response(feed_conn, 200)

      assert get_resp_header(rss_conn, "content-type") ==
               get_resp_header(feed_conn, "content-type")
    end
  end
end
