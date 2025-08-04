defmodule JolaDevWeb.ErrorHTMLTest do
  use JolaDevWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(JolaDevWeb.ErrorHTML, "404", "html", [])
    assert html =~ "Page Not Found"
    assert html =~ "The page you're looking for doesn't exist"
    assert html =~ "Go to Homepage"
    assert html =~ "View Blog Posts"
  end

  test "renders 500.html" do
    html = render_to_string(JolaDevWeb.ErrorHTML, "500", "html", [])
    assert html =~ "Internal Server Error"
    assert html =~ "Something went wrong on our end"
    assert html =~ "Go to Homepage"
  end
end
