defmodule JolaDevWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use JolaDevWeb, :controller` and
  `use JolaDevWeb, :live_view`.
  """
  use JolaDevWeb, :html

  embed_templates "layouts/*"

  attr :current_path, :string, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <header class="border-b border-border">
        <.navigation social_links>
          <:link href="/" active={@current_path == "/"}>Home</:link>
          <:link href="/about" active={@current_path == "/about"}>About</:link>
          <:link
            href="/posts"
            active={is_binary(@current_path) and String.starts_with?(@current_path, "/posts")}
          >
            Blog
          </:link>
          <:link href="/newsletter" active={@current_path == "/newsletter"}>Newsletter</:link>
          <:link href="/projects" active={@current_path == "/projects"}>Projects</:link>
          <:link href="/talks" active={@current_path == "/talks"}>Talks</:link>
        </.navigation>
      </header>

      <main class="flex-grow">
        {render_slot(@inner_block)}
      </main>

      <.footer tagline={tagline()} />
    </div>
    """
  end

  def tagline do
    Enum.random([
      "Flibbertigibetting",
      "Reticulating splines",
      "Contemplating",
      "Innovating",
      "Architecting",
      "Optimizing",
      "Debugging reality",
      "Compiling thoughts",
      "Building software with care",
      "Building software with love",
      "Building software with passion"
    ])
  end
end
