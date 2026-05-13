defmodule JolaDev.OGImage do
  @moduledoc """
  Per-page Open Graph image lookup. All content from
  `JolaDev.OGImage.Catalog` is rendered at compile time via
  `JolaDev.OGImage.Renderer` and baked into the `@images` module
  attribute, then served at runtime from `JolaDevWeb.Plugs.OGImage`.
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

  @default_image (
                   {title, description} = Catalog.content_for("home")
                   Renderer.generate_bytes(title, description)
                 )

  @doc """
  Returns the public asset path for a slug's OG image. Used so the
  path scheme stays consistent.
  """
  def path_for(slug) when is_binary(slug), do: "/images/og/#{slug}.png"

  def image_for(slug) do
    with :error <- image_for_slug(slug) do
      {:ok, @default_image}
    end
  end

  def default_image do
    @default_image
  end

  defp image_for_slug(slug) do
    if @images do
      Map.fetch(@images, slug)
    else
      with {title, description} <- Catalog.content_for(slug) do
        {:ok, Renderer.generate_bytes(title, description)}
      end
    end
  end
end
