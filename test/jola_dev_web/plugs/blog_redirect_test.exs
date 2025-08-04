defmodule JolaDevWeb.Plugs.BlogRedirectTest do
  use JolaDevWeb.ConnCase, async: true
  alias JolaDevWeb.Plugs.BlogRedirect

  describe "call/2" do
    test "redirects valid blog posts from blog.jola.dev to jola.dev", %{conn: conn} do
      # Get a valid post ID
      post_id = List.first(JolaDev.Blog.ids())

      conn =
        conn
        |> Map.put(:host, "blog.jola.dev")
        |> Map.put(:request_path, "/#{post_id}")
        |> BlogRedirect.call([])

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["https://jola.dev/posts/#{post_id}"]
      assert conn.halted
    end

    test "does not redirect invalid paths on blog.jola.dev", %{conn: conn} do
      original_conn =
        conn
        |> Map.put(:host, "blog.jola.dev")
        |> Map.put(:request_path, "/non-existent-post")

      result_conn = BlogRedirect.call(original_conn, [])

      assert result_conn == original_conn
      refute result_conn.halted
    end

    test "does not redirect on non-blog.jola.dev hosts", %{conn: conn} do
      post_id = List.first(JolaDev.Blog.ids())

      original_conn =
        conn
        |> Map.put(:host, "jola.dev")
        |> Map.put(:request_path, "/#{post_id}")

      result_conn = BlogRedirect.call(original_conn, [])

      assert result_conn == original_conn
      refute result_conn.halted
    end

    test "handles paths with leading slash correctly", %{conn: conn} do
      post_id = List.first(JolaDev.Blog.ids())

      conn =
        conn
        |> Map.put(:host, "blog.jola.dev")
        |> Map.put(:request_path, "/#{post_id}")
        |> BlogRedirect.call([])

      assert get_resp_header(conn, "location") == ["https://jola.dev/posts/#{post_id}"]
    end
  end

  describe "init/1" do
    test "returns empty list" do
      assert BlogRedirect.init(:anything) == []
    end
  end
end
