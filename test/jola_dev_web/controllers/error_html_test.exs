defmodule JolaDevWeb.ErrorHTMLTest do
  use JolaDevWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(JolaDevWeb.ErrorHTML, "404", "html", conn: %Plug.Conn{assigns: %{}})
    assert html =~ "Page Not Found"
    assert html =~ "The page you're looking for seems to have wandered off"
  end

  test "renders 500.html" do
    html = render_to_string(JolaDevWeb.ErrorHTML, "500", "html", conn: %Plug.Conn{assigns: %{}})
    assert html =~ "Internal Server Error"
    assert html =~ "Something has gone terribly wrong"
  end
end
