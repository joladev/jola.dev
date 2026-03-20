defmodule JolaDev.LlmsTxtTest do
  use ExUnit.Case, async: true

  describe "generate/0" do
    test "includes site header and pages" do
      content = JolaDev.LlmsTxt.generate()

      assert content =~ "# jola.dev"
      assert content =~ "https://jola.dev/about"
      assert content =~ "https://jola.dev/posts"
      assert content =~ "https://jola.dev/projects"
      assert content =~ "https://jola.dev/talks"
    end

    test "includes blog post links" do
      content = JolaDev.LlmsTxt.generate()

      for post <- JolaDev.Blog.all_posts() do
        assert content =~ post.title
        assert content =~ "https://jola.dev/posts/#{post.id}"
      end
    end
  end

  describe "generate_full/0" do
    test "includes post descriptions" do
      content = JolaDev.LlmsTxt.generate_full()

      for post <- JolaDev.Blog.all_posts() do
        assert content =~ post.description
      end
    end
  end
end
