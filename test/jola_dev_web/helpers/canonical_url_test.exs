defmodule JolaDevWeb.Helpers.CanonicalUrlTest do
  use JolaDevWeb.ConnCase, async: true

  alias JolaDevWeb.Helpers.CanonicalUrl

  describe "canonical_url/1" do
    test "generates canonical URL for home page", %{conn: conn} do
      conn = get(conn, ~p"/")
      url = CanonicalUrl.canonical_url(conn)

      assert url == "https://jola.dev/"
    end

    test "generates canonical URL for blog index", %{conn: conn} do
      conn = get(conn, ~p"/posts")
      url = CanonicalUrl.canonical_url(conn)

      assert url == "https://jola.dev/posts"
    end

    test "generates canonical URL for blog post", %{conn: conn} do
      conn = get(conn, ~p"/posts/test-post")
      url = CanonicalUrl.canonical_url(conn)

      assert url == "https://jola.dev/posts/test-post"
    end

    test "handles paths with multiple segments", %{conn: conn} do
      conn = get(conn, ~p"/about")
      url = CanonicalUrl.canonical_url(conn)

      assert url == "https://jola.dev/about"
    end
  end
end
