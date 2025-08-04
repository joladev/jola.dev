defmodule JolaDevWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use JolaDevWeb, :html

  embed_templates "page_html/*"

  @status_messages [
    "Vibing",
    "Calculating",
    "Undulating",
    "Reticulating splines",
    "Contemplating",
    "Innovating",
    "Architecting",
    "Optimizing",
    "Debugging reality",
    "Compiling thoughts"
  ]

  def random_status do
    Enum.random(@status_messages)
  end
end
