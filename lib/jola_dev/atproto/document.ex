defmodule JolaDev.Atproto.Document do
  @moduledoc """
  This is used to represent blog posts
  """

  @enforce_keys [:rkey, :site, :title, :path, :published_at]
  defstruct @enforce_keys ++ [:updated_at, :description, :text_content, :tags, :cover_image]
end
