defmodule JolaDevWeb.Helpers.CanonicalUrl do
  @moduledoc """
  Helper module for generating canonical URLs for SEO purposes.
  """

  @doc """
  Generates a canonical URL for the current request.
  """
  def canonical_url(conn) do
    "https://jola.dev#{conn.request_path}"
  end
end
