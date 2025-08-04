defmodule JolaDevWeb.BlogHelpers do
  @moduledoc """
  Helper functions for blog views.
  """

  def estimate_reading_time(body) do
    words =
      body
      |> String.split(~r/\s+/)
      |> length()

    max(div(words, 200), 1)
  end
end
