defmodule JolaDev.Blog.MarkdownConverter do
  @moduledoc """
  Custom markdown converter that adds syntax highlighting to code blocks.
  """
  @regex ~r/<code[^<]*>([^<]*)<\/code>/

  def convert(filepath, body, _attrs, opts) do
    if Path.extname(filepath) in [".md", ".markdown"] do
      earmark_opts = Keyword.fetch!(opts, :earmark_options)
      html = Earmark.as_html!(body, earmark_opts)

      highlight(html)
    end
  end

  defp highlight(html) do
    Regex.replace(
      @regex,
      html,
      fn _, code ->
        highlight_code_block(code)
      end
    )
  end

  defp highlight_code_block(code) do
    {lang, {lexer, opts}} = Makeup.Registry.fetch_lexer_by_name("elixir")

    highlighted =
      code
      |> unescape_html()
      |> IO.iodata_to_binary()
      |> Makeup.highlight_inner_html(
        lexer: lexer,
        lexer_options: opts,
        formatter_options: [highlight_tag: "span"]
      )

    ~s(<code class="makeup #{lang}">#{highlighted}</code>)
  end

  entities = [{"&amp;", ?&}, {"&lt;", ?<}, {"&gt;", ?>}, {"&quot;", ?"}, {"&#39;", ?'}]

  for {encoded, decoded} <- entities do
    defp unescape_html(unquote(encoded) <> rest), do: [unquote(decoded) | unescape_html(rest)]
  end

  defp unescape_html(<<c, rest::binary>>), do: [c | unescape_html(rest)]
  defp unescape_html(<<>>), do: []
end
