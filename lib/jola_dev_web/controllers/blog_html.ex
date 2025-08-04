defmodule JolaDevWeb.BlogHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use JolaDevWeb, :html

  embed_templates "blog_html/*"
end
