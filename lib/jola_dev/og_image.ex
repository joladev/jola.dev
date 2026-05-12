defmodule JolaDev.OGImage do
  @moduledoc """
  Per-page Open Graph image lookup. All images are rendered at compile time
  via `JolaDev.OGImage.Renderer` and baked into the `@baked` module
  attribute, then served at runtime from `JolaDevWeb.OGImageController`.

  See `JolaDev.OGImage.Renderer` for the rendering primitives.
  """

  alias JolaDev.OGImage.Renderer

  @dev_mode Application.compile_env!(:jola_dev, :og_image_dev_mode)
  @baked if not @dev_mode,
           do:
             Map.new(Renderer.all_slugs(), fn slug ->
               {title, description} = Renderer.content_for(slug)
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
  def bytes_for(slug) do
    if @baked do
      Map.fetch(@baked, slug)
    else
      case Renderer.content_for(slug) do
        {title, description} ->
          {:ok, Renderer.generate_bytes(title, description)}

        :error ->
          :error
      end
    end
  end
end
