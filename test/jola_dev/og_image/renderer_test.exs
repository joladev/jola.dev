defmodule JolaDev.OGImage.RendererTest do
  use ExUnit.Case, async: true
  alias JolaDev.OGImage.Renderer

  describe "generate_bytes/2" do
    test "returns a PNG binary" do
      bytes = Renderer.generate_bytes("Title", "Description.")

      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = bytes
    end
  end

  describe "content_for/1" do
    test "returns {title, description} for each static slug" do
      for slug <- ~w(home about projects talks posts) do
        assert {title, description} = Renderer.content_for(slug)
        assert is_binary(title)
        assert is_binary(description)
      end
    end

    test "returns post title and description for a known post slug" do
      post = List.first(JolaDev.Blog.all_posts())

      assert {title, description} = Renderer.content_for("posts/#{post.id}")
      assert title == post.title
      assert description == post.description
    end

    test "returns tag title and description for a known tag slug" do
      tag = List.first(JolaDev.Blog.all_tags())

      assert {title, description} = Renderer.content_for("posts/tag/#{tag}")
      assert title =~ tag
      assert description =~ tag
    end

    test "returns :error for an unknown post slug" do
      assert Renderer.content_for("posts/this-does-not-exist") == :error
    end

    test "returns :error for an unknown tag slug" do
      assert Renderer.content_for("posts/tag/this-tag-does-not-exist") == :error
    end

    test "returns :error for an unknown slug" do
      assert Renderer.content_for("random/path") == :error
    end
  end

  describe "all_slugs/0" do
    test "includes the static pages" do
      slugs = Renderer.all_slugs()

      for static <- ~w(home about projects talks posts) do
        assert static in slugs
      end
    end

    test "includes every blog post" do
      slugs = Renderer.all_slugs()
      post_slugs = Enum.map(JolaDev.Blog.all_posts(), &"posts/#{&1.id}")

      for slug <- post_slugs do
        assert slug in slugs
      end
    end

    test "includes every tag" do
      slugs = Renderer.all_slugs()
      tag_slugs = Enum.map(JolaDev.Blog.all_tags(), &"posts/tag/#{&1}")

      for slug <- tag_slugs do
        assert slug in slugs
      end
    end
  end
end
