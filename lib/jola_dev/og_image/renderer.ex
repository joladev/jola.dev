defmodule JolaDev.OGImage.Renderer do
  @moduledoc """
  Pure image-rendering primitives for OGImage. Kept in a sibling module so
  that `JolaDev.OGImage` can call into it from a compile-time module
  attribute (Elixir module attributes can't call functions defined in the
  same module they're being compiled into).

  Requires Inter installed system-wide so fontconfig can find it
  (`brew install --cask font-inter` on macOS, `fonts-inter` apt package
  in the Docker builder stage).
  """

  @width 1200
  @height 630
  @padding 80
  @logo_size 72
  @logo_gap 20
  @wordmark_size 48
  @title_size 72
  @title_bottom_y 470
  @description_size 32
  @description_y 500
  @background "#0a0a0a"
  @foreground "white"
  @muted "#a3a3a3"
  @grid_color "#1e1e1e"
  @grid_spacing 50

  @logo_path "priv/static/images/logo.png"

  def generate_bytes(title, description) when is_binary(title) and is_binary(description) do
    title
    |> build_canvas(description)
    |> Image.write!(:memory, suffix: ".png")
  end

  defp build_canvas(title, description) do
    canvas = Image.new!(@width, @height, color: @background)

    canvas
    |> draw_grid()
    |> place_logo()
    |> place_wordmark()
    |> place_text(title,
      font_size: @title_size,
      font_weight: :bold,
      color: @foreground,
      y_bottom: @title_bottom_y
    )
    |> place_text(description,
      font_size: @description_size,
      color: @muted,
      y: @description_y
    )
  end

  defp draw_grid(image) do
    image
    |> draw_vertical_lines(@grid_spacing)
    |> draw_horizontal_lines(@grid_spacing)
  end

  defp draw_vertical_lines(image, spacing) do
    Enum.reduce(spacing..(@width - 1)//spacing, image, fn x, acc ->
      Image.Draw.line!(acc, x, 0, x, @height - 1, color: @grid_color)
    end)
  end

  defp draw_horizontal_lines(image, spacing) do
    Enum.reduce(spacing..(@height - 1)//spacing, image, fn y, acc ->
      Image.Draw.line!(acc, 0, y, @width - 1, y, color: @grid_color)
    end)
  end

  defp place_logo(canvas) do
    {:ok, logo} = Image.open(@logo_path)
    {:ok, resized} = Image.thumbnail(logo, @logo_size)
    Image.compose!(canvas, resized, x: @padding, y: @padding)
  end

  defp place_wordmark(canvas) do
    {:ok, text} =
      Image.Text.text("jola.dev",
        font: "Inter",
        font_size: @wordmark_size,
        font_weight: :bold,
        text_fill_color: @foreground
      )

    y_offset = @padding + div(@logo_size - Image.height(text), 2)
    Image.compose!(canvas, text, x: @padding + @logo_size + @logo_gap, y: y_offset)
  end

  defp place_text(canvas, content, opts) do
    base = [
      font: "Inter",
      font_size: Keyword.fetch!(opts, :font_size),
      text_fill_color: Keyword.fetch!(opts, :color),
      width: @width - 2 * @padding
    ]

    text_opts =
      case Keyword.get(opts, :font_weight) do
        nil -> base
        weight -> Keyword.put(base, :font_weight, weight)
      end

    {:ok, text} = Image.Text.text(content, text_opts)

    y =
      case Keyword.fetch(opts, :y) do
        {:ok, y} -> y
        :error -> Keyword.fetch!(opts, :y_bottom) - Image.height(text)
      end

    Image.compose!(canvas, text, x: @padding, y: y)
  end
end
