defmodule JolaDevWeb.Plugs.OGImageTest do
  use JolaDevWeb.ConnCase, async: true
  alias JolaDevWeb.Plugs.OGImage

  describe "call/2" do
    test "serves a PNG for a static slug", %{conn: conn} do
      conn =
        conn
        |> Map.put(:request_path, "/images/og/home.png")
        |> OGImage.call([])

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = conn.resp_body
      assert conn.halted
    end

    test "serves a PNG for a known post slug", %{conn: conn} do
      post = List.first(JolaDev.Blog.all_posts())

      conn =
        conn
        |> Map.put(:request_path, "/images/og/posts/#{post.id}.png")
        |> OGImage.call([])

      assert conn.status == 200
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = conn.resp_body
    end

    test "serves a PNG for a known tag slug", %{conn: conn} do
      tag = List.first(JolaDev.Blog.all_tags())

      conn =
        conn
        |> Map.put(:request_path, "/images/og/posts/tag/#{tag}.png")
        |> OGImage.call([])

      assert conn.status == 200
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = conn.resp_body
    end

    test "falls through for an unknown OG slug", %{conn: conn} do
      original = Map.put(conn, :request_path, "/images/og/no-such-page.png")

      result = OGImage.call(original, [])

      assert result == original
      refute result.halted
    end

    test "passes through for paths outside /images/og/", %{conn: conn} do
      original = Map.put(conn, :request_path, "/posts/running-local-models-on-m4")

      result = OGImage.call(original, [])

      assert result == original
      refute result.halted
    end
  end
end
