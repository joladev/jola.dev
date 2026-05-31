defmodule JolaDev.Blog.MarkdownConverterTest do
  use ExUnit.Case, async: true
  alias JolaDev.Blog.MarkdownConverter

  describe "convert/4" do
    test "converts markdown to HTML" do
      body = "# Hello World\n\nThis is a paragraph."

      html = MarkdownConverter.convert("test.md", body, %{}, [])

      assert html =~ "<h1>"
      assert html =~ "Hello World"
      assert html =~ "<p>"
      assert html =~ "This is a paragraph."
    end

    test "highlights Elixir code blocks with linked classes" do
      body = """
      Here is some code:

      ```elixir
      defmodule Test do
        def hello, do: "world"
      end
      ```
      """

      html = MarkdownConverter.convert("test.md", body, %{}, [])

      assert html =~ ~s(<pre class="lumis">)
      assert html =~ ~s(class="language-elixir")
      assert html =~ "defmodule"
      assert html =~ "<span "
    end

    test "leaves inline code unhighlighted" do
      body = "Use `mix test` to run tests."

      html = MarkdownConverter.convert("test.md", body, %{}, [])

      assert html =~ "<code>mix test</code>"
      refute html =~ "<pre"
    end

    test "highlights code containing HTML-entity-like text" do
      body = """
      ```elixir
      1 &lt; 2 &amp;&amp; 3 &gt; 2
      ```
      """

      html = MarkdownConverter.convert("test.md", body, %{}, [])

      assert html =~ ~s(<pre class="lumis">)
      assert html =~ "<span "
    end
  end
end
