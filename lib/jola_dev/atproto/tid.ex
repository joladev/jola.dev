defmodule JolaDev.Atproto.TID do
  @moduledoc """
  Timestamp Identifiers are commonly used in atproto for record keys.

  https://atproto.com/specs/tid
  """

  @alphabet "234567abcdefghijklmnopqrstuvwxyz"

  @doc """
  Generate a deterministic TID for a given id and time.

  The date makes the TIDs sortable, although that's not strictly necessary. The
  id reduces the already small risk of collisions.
  """
  def deterministic(id, %Date{} = date) when is_binary(id) do
    # 10-bit clock ID from the top bits of the id's sha256, so the same
    # id always resolves to the same TID.
    <<clock_id::10, _::bits>> = :crypto.hash(:sha256, id)
    datetime = DateTime.new!(date, ~T[00:00:00])
    timestamp_μs = DateTime.to_unix(datetime, :microsecond) * 1024

    (timestamp_μs + clock_id)
    |> Integer.digits(32)
    |> Enum.map_join(&<<:binary.at(@alphabet, &1)>>)
    |> String.pad_leading(13, "2")
  end
end
