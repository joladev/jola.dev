defmodule JolaDevWeb.Plugs.StripTrailingSlash do
  @moduledoc """
  Plug that 301-redirects any non-root request path ending in `/`
  to the same path without the trailing slash, preserving the query string.
  Prevents duplicate-content issues where `/posts` and `/posts/` both serve 200.
  """
  import Plug.Conn

  def init(_), do: []

  def call(%Plug.Conn{request_path: "/"} = conn, _opts), do: conn

  def call(%Plug.Conn{request_path: path} = conn, _opts) do
    if String.ends_with?(path, "/") do
      target = String.trim_trailing(path, "/")

      target =
        case conn.query_string do
          "" -> target
          qs -> target <> "?" <> qs
        end

      conn
      |> put_resp_header("location", target)
      |> send_resp(:moved_permanently, "")
      |> halt()
    else
      conn
    end
  end
end
