defmodule JolaDevWeb.LlmsControllerTest do
  use JolaDevWeb.ConnCase, async: true

  test "GET /llms.txt returns plain text with site info", %{conn: conn} do
    conn = get(conn, "/llms.txt")

    assert response_content_type(conn, :text) =~ "text/plain"
    body = response(conn, 200)
    assert body =~ "# jola.dev"
    assert body =~ "https://jola.dev/posts"
  end

  test "GET /llms-full.txt returns plain text with post descriptions", %{conn: conn} do
    conn = get(conn, "/llms-full.txt")

    assert response_content_type(conn, :text) =~ "text/plain"
    body = response(conn, 200)
    assert body =~ "# jola.dev"

    post = List.first(JolaDev.Blog.all_posts())
    assert body =~ post.description
  end
end
