defmodule JolaDev.OGImage.Renderer do
  @moduledoc """
  Pure image-rendering primitives for OGImage.
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

  def render(title, description) when is_binary(title) and is_binary(description) do
    image =
      title
      |> build_canvas(description)
      |> Image.write!(:memory, suffix: ".png")

    {:ok, image}
  end

  defp build_canvas(title, description) do
    image = Image.new!(@width, @height, color: @background)

    image
    |> draw_grid()
    |> place_logo()
    |> render_wordmark()
    |> render_title(title)
    |> render_description(description)
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

  defp render_wordmark(canvas) do
    {:ok, text} =
      Image.Text.text("jola.dev",
        font: "Schibsted Grotesk",
        font_size: @wordmark_size,
        font_weight: :bold,
        text_fill_color: @foreground
      )

    y = @padding + div(@logo_size - Image.height(text), 2)
    Image.compose!(canvas, text, x: @padding + @logo_size + @logo_gap, y: y)
  end

  defp render_title(canvas, title) do
    {:ok, text} =
      Image.Text.text(title,
        font: "Schibsted Grotesk",
        font_size: @title_size,
        font_weight: :bold,
        text_fill_color: @foreground,
        width: @width - 2 * @padding
      )

    Image.compose!(canvas, text, x: @padding, y: @title_bottom_y - Image.height(text))
  end

  defp render_description(canvas, description) do
    {:ok, text} =
      Image.Text.text(description,
        font: "Hanken Grotesk",
        font_size: @description_size,
        text_fill_color: @muted,
        width: @width - 2 * @padding
      )

    Image.compose!(canvas, text, x: @padding, y: @description_y)
  end
end
