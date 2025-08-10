defmodule JolaDevWeb.Plugs.BlogRedirect do
  @moduledoc """
  Plug that redirects requests from the old blog.jola.dev domain to the new jola.dev/posts path.
  """
  import Plug.Conn

  def init(_), do: []

  def call(conn, _opts) do
    if conn.host == "blog.jola.dev" do
      ids = JolaDev.Blog.ids()
      path = strip_path(conn.request_path)

      path =
        if path in ids do
          "posts/" <> path
        else
          path
        end

      conn
      |> put_resp_header("location", "https://jola.dev/" <> path)
      |> send_resp(:moved_permanently, "")
      |> halt()
    else
      conn
    end
  end

  defp strip_path("/" <> path), do: path
  defp strip_path(path), do: path
end
