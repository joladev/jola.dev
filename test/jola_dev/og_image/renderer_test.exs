defmodule JolaDev.OGImage.RendererTest do
  use ExUnit.Case, async: true
  alias JolaDev.OGImage.Renderer

  describe "generate_bytes/2" do
    test "returns a PNG binary" do
      bytes = Renderer.render("Title", "Description.")

      assert {:ok, <<137, "PNG\r\n", 26, "\n", _rest::binary>>} = bytes
    end
  end
end
