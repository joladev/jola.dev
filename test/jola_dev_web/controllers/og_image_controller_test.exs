defmodule JolaDevWeb.OGImageControllerTest do
  use JolaDevWeb.ConnCase, async: true

  describe "GET /images/og/*slug" do
    test "serves a PNG for a static slug", %{conn: conn} do
      conn = get(conn, ~p"/images/og/home.png")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]

      assert get_resp_header(conn, "cache-control") == [
               "public, max-age=31536000"
             ]

      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = conn.resp_body
    end

    test "serves a PNG for a known post slug", %{conn: conn} do
      post = List.first(JolaDev.Blog.all_posts())

      conn = get(conn, "/images/og/posts/#{post.id}.png")

      assert conn.status == 200
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = conn.resp_body
    end

    test "serves a PNG for a known tag slug", %{conn: conn} do
      tag = List.first(JolaDev.Blog.all_tags())

      conn = get(conn, "/images/og/posts/tag/#{tag}.png")

      assert conn.status == 200
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = conn.resp_body
    end

    test "returns 404 for an unknown slug", %{conn: conn} do
      conn = get(conn, ~p"/images/og/no-such-page.png")

      assert conn.status == 404
    end
  end
end
