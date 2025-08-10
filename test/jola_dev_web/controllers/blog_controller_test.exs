defmodule JolaDevWeb.BlogControllerTest do
  use JolaDevWeb.ConnCase, async: true

  describe "index" do
    test "lists all blog posts", %{conn: conn} do
      conn = get(conn, ~p"/posts")

      assert html_response(conn, 200)
      assert conn.assigns.page_title == "jola.dev - Posts"
      assert is_list(conn.assigns.posts)
      assert length(conn.assigns.posts) > 0
    end
  end

  describe "show" do
    test "displays individual post when exists", %{conn: conn} do
      # Get a valid post ID
      post = List.first(JolaDev.Blog.all_posts())

      conn = get(conn, ~p"/posts/#{post.id}")

      assert html_response(conn, 200)
      assert conn.assigns.page_title == "jola.dev - #{post.title}"
      assert conn.assigns.post.id == post.id
    end

    test "returns 404 for non-existent post", %{conn: conn} do
      conn = get(conn, ~p"/posts/non-existent-post-id")

      html = html_response(conn, 404)
      assert html =~ "Page Not Found"
      assert html =~ "The page you're looking for seems to have wandered off"
    end
  end
end
