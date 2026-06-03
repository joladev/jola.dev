defmodule JolaDevWeb.WellKnownController do
  use JolaDevWeb, :controller

  def publication(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> text(JolaDev.Atproto.publication_uri())
  end
end
