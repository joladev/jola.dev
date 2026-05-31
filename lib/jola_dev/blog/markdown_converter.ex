defmodule JolaDev.Blog.MarkdownConverter do
  @moduledoc """
  Converts post markdown to HTML via MDEx with linked-class syntax highlighting.
  """

  def convert(filepath, body, _attrs, _opts) do
    if Path.extname(filepath) in [".md", ".markdown"] do
      MDEx.to_html!(body,
        extension: [
          strikethrough: true,
          table: true,
          autolink: true,
          tasklist: true,
          footnotes: true
        ],
        render: [unsafe: true],
        syntax_highlight: [formatter: :html_linked]
      )
    end
  end
end
