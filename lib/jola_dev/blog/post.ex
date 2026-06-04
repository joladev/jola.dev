defmodule JolaDev.Blog.Post do
  @moduledoc """
  Struct representing a blog post with metadata and content.
  """
  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [
    :id,
    :author,
    :title,
    :body,
    :description,
    :tags,
    :date,
    :last_modified,
    :canonical_url,
    :text_content
  ]

  def build(filename, attrs, body) do
    [year, month_day_id] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> Enum.take(-2)

    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    last_modified = parse_last_modified(Map.get(attrs, :last_modified), date)

    attrs =
      attrs
      |> Map.put(:last_modified, last_modified)
      |> Map.put(:text_content, parse_text_content(body))

    struct!(__MODULE__, [id: id, date: date, body: body] ++ Map.to_list(attrs))
  end

  defp parse_last_modified(nil, default), do: default
  defp parse_last_modified(%Date{} = date, _default), do: date

  defp parse_last_modified(string, _default) when is_binary(string),
    do: Date.from_iso8601!(string)

  defp parse_text_content(body) do
    body
    |> MDEx.parse_document!(
      extension: [
        strikethrough: true,
        table: true,
        autolink: true,
        tasklist: true,
        footnotes: true
      ]
    )
    |> MDEx.to_markdown!()
  end
end
