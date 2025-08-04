defmodule JolaDevWeb.PageControllerTest do
  use JolaDevWeb.ConnCase, async: true

  describe "home" do
    test "GET / renders home page with recent posts", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert html_response(conn, 200) =~ "jola.dev"
      assert conn.assigns.page_title == "jola.dev"
      assert is_list(conn.assigns.recent_posts)
      assert length(conn.assigns.recent_posts) == 3
    end
  end

  describe "about" do
    test "GET /about renders about page", %{conn: conn} do
      conn = get(conn, ~p"/about")

      assert html_response(conn, 200)
      assert conn.assigns.page_title == "jola.dev - About"
    end
  end

  describe "projects" do
    test "GET /projects renders projects page", %{conn: conn} do
      conn = get(conn, ~p"/projects")

      assert html_response(conn, 200) =~ "HexDiff"
      assert conn.assigns.page_title == "jola.dev - Projects"
    end
  end

  describe "talks" do
    test "GET /talks renders talks page", %{conn: conn} do
      conn = get(conn, ~p"/talks")

      assert html_response(conn, 200)
      assert conn.assigns.page_title == "jola.dev - Talks"
    end
  end

  test "GET /posts", %{conn: conn} do
    conn = get(conn, ~p"/posts")
    html = html_response(conn, 200)

    assert html =~ "Announcing Hex Diff"
    assert html =~ "Building Hex Diff"
    assert html =~ "Push-based GenStage"
  end

  test "GET /posts/announcing-hex-diff", %{conn: conn} do
    conn = get(conn, ~p"/posts/announcing-hex-diff")
    assert html_response(conn, 200) =~ "Announcing Hex Diff"
  end
end
