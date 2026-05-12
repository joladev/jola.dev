defmodule JolaDevWeb.Helpers.OGImage do
  @moduledoc """
  Builds URLs for OG images from assigns and falls back to request_path.
  """
  use JolaDevWeb, :verified_routes

  def url_for(%{assigns: %{post: post}}), do: build("posts/#{post.id}")
  def url_for(%{assigns: %{tag: tag}}), do: build("posts/tag/#{tag}")
  def url_for(%{request_path: "/"}), do: build("home")
  def url_for(%{request_path: "/" <> rest}), do: build(rest)

  defp build(slug),
    do: unverified_url(JolaDevWeb.Endpoint, JolaDev.OGImage.path_for(slug))
end
