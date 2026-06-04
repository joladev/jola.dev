defmodule JolaDev.Blog.Parser do
  @moduledoc """
  Custom NimblePublisher parser. Runs before the HTML converter, so it's
  the one place that still has the raw markdown body. We compute the
  plaintext (markdown) `text_content` here and pass it through too.
  """

  @extension [
    strikethrough: true,
    table: true,
    autolink: true,
    tasklist: true,
    footnotes: true
  ]

  def parse(_path, contents) do
    # Get the Elixir map out of the frontmatter, copied from NimblePublisher.
    [frontmatter, body] = :binary.split(contents, ["\n---\n", "\r\n---\r\n"])
    {%{} = attrs, _} = Code.eval_string(frontmatter, [])

    {Map.put(attrs, :text_content, to_markdown(body)), body}
  end

  defp to_markdown(body) do
    body
    |> MDEx.parse_document!(extension: @extension)
    |> MDEx.to_markdown!()
  end
end
