defmodule JolaDev.Blog.Post do
  @moduledoc """
  Struct representing a blog post with metadata and content.
  """
  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [:id, :author, :title, :body, :description, :tags, :date, :last_modified]

  def build(filename, attrs, body) do
    [year, month_day_id] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> Enum.take(-2)

    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    last_modified = parse_last_modified(Map.get(attrs, :last_modified), date)

    attrs = Map.put(attrs, :last_modified, last_modified)
    struct!(__MODULE__, [id: id, date: date, body: body] ++ Map.to_list(attrs))
  end

  defp parse_last_modified(nil, default), do: default
  defp parse_last_modified(%Date{} = date, _default), do: date

  defp parse_last_modified(string, _default) when is_binary(string),
    do: Date.from_iso8601!(string)
end
