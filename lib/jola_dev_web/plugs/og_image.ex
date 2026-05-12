defmodule JolaDevWeb.Plugs.OGImage do
  @moduledoc """
  Serves Open Graph preview images from `JolaDev.OGImage`. Intercepts any
  `/images/og/<slug>.png` request, looks up the baked PNG bytes, and sends
  them with appropriate cache headers. Falls through for unknown slugs so
  Phoenix's router can render a 404.
  """

  @behaviour Plug

  import Plug.Conn

  @dev_mode Application.compile_env!(:jola_dev, :og_image_dev_mode)
  @cache_control if @dev_mode, do: "public, max-age=0", else: "public, max-age=31536000"

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{request_path: "/images/og/" <> rest} = conn, _) do
    slug = String.replace_suffix(rest, ".png", "")

    case JolaDev.OGImage.image_for(slug) do
      {:ok, bytes} ->
        conn
        |> put_resp_content_type("image/png")
        |> put_resp_header("cache-control", @cache_control)
        |> send_resp(200, bytes)
        |> halt()

      :error ->
        # Let the request fall through so Phoenix handles the 404
        conn
    end
  end

  def call(conn, _), do: conn
end
