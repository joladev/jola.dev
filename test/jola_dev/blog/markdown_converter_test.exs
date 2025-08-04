defmodule JolaDev.Blog.MarkdownConverterTest do
  use ExUnit.Case, async: true
  alias JolaDev.Blog.MarkdownConverter

  describe "convert/4" do
    test "converts markdown to HTML" do
      body = "# Hello World\n\nThis is a paragraph."
      opts = [earmark_options: %Earmark.Options{}]

      html = MarkdownConverter.convert("test.md", body, %{}, opts)

      assert html =~ "<h1>"
      assert html =~ "Hello World"
      assert html =~ "<p>"
      assert html =~ "This is a paragraph."
    end

    test "highlights Elixir code blocks" do
      body = """
      Here is some code:

      ```elixir
      defmodule Test do
        def hello, do: "world"
      end
      ```
      """

      opts = [earmark_options: %Earmark.Options{}]

      html = MarkdownConverter.convert("test.md", body, %{}, opts)

      assert html =~ ~s(<code class="makeup ok">)
      assert html =~ "defmodule"
      assert html =~ "<span"
    end

    test "handles inline code" do
      body = "Use `mix test` to run tests."
      opts = [earmark_options: %Earmark.Options{}]

      html = MarkdownConverter.convert("test.md", body, %{}, opts)

      assert html =~ "<code"
      # Inline code gets highlighted too
      assert html =~ ~s(<span class="n">mix</span>)
      assert html =~ ~s(<span class="n">test</span>)
    end

    test "highlights code with HTML entities" do
      body = """
      ```elixir
      1 &lt; 2 &amp;&amp; 3 &gt; 2
      ```
      """

      opts = [earmark_options: %Earmark.Options{}]

      html = MarkdownConverter.convert("test.md", body, %{}, opts)

      # The code should be properly highlighted with makeup
      assert html =~ ~s(<code class="makeup ok">)
      # HTML entities are parsed as Elixir syntax
      # &lt; becomes & + lt; which are highlighted separately
      assert html =~ ~s(<span class="o">&amp;</span>)
      assert html =~ ~s(<span class="n">lt</span>)
    end
  end
end
