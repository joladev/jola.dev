defmodule JolaDev.OGImage do
  @moduledoc """
  Per-page Open Graph image lookup. All images are rendered at compile time
  via `JolaDev.OGImage.Renderer` and baked into the `@images` module
  attribute, then served at runtime from `JolaDevWeb.Plugs.OGImage`.

  See `JolaDev.OGImage.Renderer` for the rendering primitives.
  """

  alias JolaDev.OGImage.Catalog
  alias JolaDev.OGImage.Renderer

  @dev_mode Application.compile_env!(:jola_dev, :og_image_dev_mode)
  @images if not @dev_mode,
            do:
              Map.new(Catalog.all_slugs(), fn slug ->
                {title, description} = Catalog.content_for(slug)
                {slug, Renderer.generate_bytes(title, description)}
              end)

  @doc """
  Returns the public asset path for a slug's OG image. Used by controllers,
  the layout, and the SEO helper so the path scheme stays consistent.
  """
  def path_for(slug) when is_binary(slug), do: "/images/og/#{slug}.png"

  @doc """
  Returns `{:ok, png_bytes}` for a known slug, `:error` otherwise.
  """
  def image_for(slug) do
    if @images do
      Map.fetch(@images, slug)
    else
      with {title, description} <- Catalog.content_for(slug) do
        {:ok, Renderer.generate_bytes(title, description)}
      end
    end
  end
end
