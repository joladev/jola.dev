defmodule JolaDev.OGImage do
  @moduledoc """
  Per-page Open Graph image lookup. All content from
  `JolaDev.OGImage.Catalog` is rendered at compile time via
  `JolaDev.OGImage.Renderer` and baked into the `@images` module
  attribute, then served at runtime from `JolaDevWeb.Plugs.OGImage`.
  """

  alias JolaDev.OGImage.Catalog
  alias JolaDev.OGImage.Renderer

  use OGMate,
    all_keys: Catalog.all_slugs(),
    content_for: Catalog,
    renderer: Renderer,
    default: Catalog.content_for("home"),
    dev_mode: Application.compile_env!(:jola_dev, :og_image_dev_mode)

  def path_for(slug) do
    "/images/og/#{slug}.png"
  end
end
