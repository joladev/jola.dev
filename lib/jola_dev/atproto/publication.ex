defmodule JolaDev.Atproto.Publication do
  @moduledoc """
  This is used to represent the record of the site itself
  """

  @enforce_keys [:name, :url]
  defstruct @enforce_keys ++ [:description, :icon]
end
