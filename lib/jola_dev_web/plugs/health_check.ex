defmodule JolaDevWeb.Plugs.HealthCheck do
  @moduledoc """
  Basic minimal health check plug
  """

  import Plug.Conn

  def init(_opts), do: []

  def call(%{request_path: "/health"} = conn, _opts) do
    conn
    |> send_resp(200, "")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
