defmodule JolaDevWeb.LlmsController do
  use JolaDevWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, JolaDev.LlmsTxt.generate())
  end

  def full(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, JolaDev.LlmsTxt.generate_full())
  end
end
