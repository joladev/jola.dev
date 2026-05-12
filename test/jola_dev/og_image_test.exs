defmodule JolaDev.OGImageTest do
  use ExUnit.Case, async: true
  alias JolaDev.OGImage

  describe "path_for/1" do
    test "returns the public asset path for a slug" do
      assert OGImage.path_for("home") == "/images/og/home.png"
      assert OGImage.path_for("posts/foo") == "/images/og/posts/foo.png"
      assert OGImage.path_for("posts/tag/elixir") == "/images/og/posts/tag/elixir.png"
    end
  end

  describe "image_for/1" do
    test "returns the baked PNG bytes for a known static slug" do
      assert {:ok, bytes} = OGImage.image_for("home")
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = bytes
    end

    test "returns the baked PNG bytes for a known post slug" do
      post = List.first(JolaDev.Blog.all_posts())

      assert {:ok, bytes} = OGImage.image_for("posts/#{post.id}")
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = bytes
    end

    test "returns the baked PNG bytes for a known tag slug" do
      tag = List.first(JolaDev.Blog.all_tags())

      assert {:ok, bytes} = OGImage.image_for("posts/tag/#{tag}")
      assert <<137, "PNG\r\n", 26, "\n", _rest::binary>> = bytes
    end

    test "returns :error for an unknown slug" do
      assert OGImage.image_for("no-such-page") == :error
    end
  end
end
