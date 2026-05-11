defmodule JolaDev.Blog.PostTest do
  use ExUnit.Case, async: true
  alias JolaDev.Blog.Post

  describe "build/3" do
    test "correctly parses filename and builds post struct" do
      filename = "2024/01-15-my-test-post.md"

      attrs = %{
        author: "Test Author",
        title: "Test Post",
        description: "Test description",
        tags: ["elixir", "testing"]
      }

      body = "<p>Test body content</p>"

      post = Post.build(filename, attrs, body)

      assert post.id == "my-test-post"
      assert post.date == ~D[2024-01-15]
      assert post.author == "Test Author"
      assert post.title == "Test Post"
      assert post.description == "Test description"
      assert post.tags == ["elixir", "testing"]
      assert post.body == "<p>Test body content</p>"
    end

    test "parses date correctly from filename format" do
      filename = "2023/12-25-christmas-post.md"
      attrs = %{author: "Santa", title: "Christmas", description: "Ho ho ho", tags: []}

      post = Post.build(filename, attrs, "")

      assert post.date == ~D[2023-12-25]
      assert post.id == "christmas-post"
    end

    test "handles multi-word ids with hyphens" do
      filename = "2024/03-10-this-is-a-long-title.md"
      attrs = %{author: "Author", title: "Title", description: "Desc", tags: []}

      post = Post.build(filename, attrs, "")

      assert post.id == "this-is-a-long-title"
    end
  end

  describe "last_modified" do
    test "defaults to the post date when not provided in frontmatter" do
      filename = "2024/01-15-my-post.md"
      attrs = %{author: "a", title: "t", description: "d", tags: []}

      post = Post.build(filename, attrs, "")

      assert post.last_modified == ~D[2024-01-15]
      assert post.last_modified == post.date
    end

    test "accepts a Date struct from frontmatter" do
      filename = "2024/01-15-my-post.md"
      attrs = %{author: "a", title: "t", description: "d", tags: [], last_modified: ~D[2024-06-01]}

      post = Post.build(filename, attrs, "")

      assert post.last_modified == ~D[2024-06-01]
    end

    test "parses an ISO 8601 date string from frontmatter" do
      filename = "2024/01-15-my-post.md"
      attrs = %{author: "a", title: "t", description: "d", tags: [], last_modified: "2024-06-01"}

      post = Post.build(filename, attrs, "")

      assert post.last_modified == ~D[2024-06-01]
    end
  end

  describe "struct enforcement" do
    test "enforces required keys" do
      assert_raise ArgumentError, fn ->
        struct!(Post, id: "test", author: "author")
      end
    end
  end
end
