defmodule JolaDevWeb.OGImageController do
  use JolaDevWeb, :controller

  @dev_mode Application.compile_env!(:jola_dev, :og_image_dev_mode)
  @cache_control if @dev_mode, do: "public, max-age=0", else: "public, max-age=31536000"

  def show(conn, %{"slug" => segments}) do
    slug =
      segments
      |> Enum.join("/")
      |> String.replace_suffix(".png", "")

    case JolaDev.OGImage.bytes_for(slug) do
      {:ok, bytes} ->
        conn
        |> put_resp_content_type("image/png")
        |> put_resp_header("cache-control", @cache_control)
        |> send_resp(200, bytes)

      :error ->
        conn
        |> put_status(:not_found)
        |> put_view(html: JolaDevWeb.ErrorHTML)
        |> render("404.html")
    end
  end
end
