defmodule JolaDevWeb.Plugs.StripTrailingSlashTest do
  use JolaDevWeb.ConnCase, async: true
  alias JolaDevWeb.Plugs.StripTrailingSlash

  describe "call/2" do
    test "redirects path with trailing slash to bare path", %{conn: conn} do
      conn =
        conn
        |> Map.put(:request_path, "/posts/")
        |> Map.put(:query_string, "")
        |> StripTrailingSlash.call([])

      assert conn.status == 301
      assert get_resp_header(conn, "location") == ["/posts"]
      assert conn.halted
    end

    test "preserves query string when redirecting", %{conn: conn} do
      conn =
        conn
        |> Map.put(:request_path, "/posts/")
        |> Map.put(:query_string, "tag=elixir&page=2")
        |> StripTrailingSlash.call([])

      assert get_resp_header(conn, "location") == ["/posts?tag=elixir&page=2"]
    end

    test "passes through root path", %{conn: conn} do
      original =
        conn
        |> Map.put(:request_path, "/")
        |> Map.put(:query_string, "")

      result = StripTrailingSlash.call(original, [])

      assert result == original
      refute result.halted
    end

    test "passes through path without trailing slash", %{conn: conn} do
      original =
        conn
        |> Map.put(:request_path, "/posts")
        |> Map.put(:query_string, "")

      result = StripTrailingSlash.call(original, [])

      assert result == original
      refute result.halted
    end

    test "redirects nested path with trailing slash", %{conn: conn} do
      conn =
        conn
        |> Map.put(:request_path, "/posts/tag/elixir/")
        |> Map.put(:query_string, "")
        |> StripTrailingSlash.call([])

      assert get_resp_header(conn, "location") == ["/posts/tag/elixir"]
      assert conn.halted
    end
  end

  describe "init/1" do
    test "returns empty list" do
      assert StripTrailingSlash.init(:anything) == []
    end
  end
end
