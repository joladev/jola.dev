defmodule JolaDevWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: JolaDevWeb.Gettext

  @doc """
  Renders a button with multiple variants.

  ## Examples

      <.button>Primary Button</.button>
      <.button variant={:secondary}>Secondary Button</.button>
      <.button variant={:ghost} icon="hero-arrow-right">Ghost Button</.button>
  """
  attr :type, :string, default: nil
  attr :variant, :atom, values: [:primary, :secondary, :ghost], default: :primary
  attr :size, :atom, values: [:sm, :md, :lg], default: :md
  attr :icon, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "inline-flex items-center justify-center rounded-lg font-medium transition-all phx-submit-loading:opacity-75",
        @variant == :primary && "bg-foreground text-background hover:opacity-90",
        @variant == :secondary &&
          "border border-border bg-background text-foreground hover:bg-surface",
        @variant == :ghost && "text-foreground hover:bg-surface",
        @size == :sm && "text-sm px-3 py-1.5",
        @size == :md && "text-sm px-4 py-2",
        @size == :lg && "text-base px-6 py-3",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
      <.icon :if={@icon} name={@icon} class="ml-2 w-4 h-4" />
    </button>
    """
  end

  @doc """
  Renders a badge component.

  ## Examples

      <.badge>Default</.badge>
      <.badge variant={:success} dot>Available</.badge>
      <.badge variant={:muted}>Draft</.badge>
  """
  attr :variant, :atom, values: [:default, :success, :muted], default: :default
  attr :dot, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
      @variant == :default && "bg-surface text-foreground",
      @variant == :success && "bg-accent/10 text-accent",
      @variant == :muted && "bg-muted/10 text-muted-foreground",
      @class
    ]}>
      <span
        :if={@dot}
        class={[
          "mr-1.5 h-1.5 w-1.5 rounded-full",
          @variant == :default && "bg-foreground",
          @variant == :success && "bg-accent",
          @variant == :muted && "bg-muted"
        ]}
      />
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def icon(%{name: "lucide-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil

  def brand_icon(assigns) do
    ~H"""
    <span class={["inline-block align-middle shrink-0", @class]}>
      <svg
        class="size-full"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 512 512"
        aria-hidden="true"
      >
        {Phoenix.HTML.raw(path_for(@name))}
      </svg>
    </span>
    """
  end

  defp path_for("github") do
    """
    <path
      d="M256 6.3C114.6 6.3 0 120.9 0 262.3c0 113.3 73.3 209 175 242.9 12.8 2.2 17.6-5.4 17.6-12.2 0-6.1-.3-26.2-.3-47.7-64.3 11.8-81-15.7-86.1-30.1-2.9-7.4-15.4-30.1-26.2-36.2-9-4.8-21.8-16.6-.3-17 20.2-.3 34.6 18.6 39.4 26.2 23 38.7 59.8 27.8 74.6 21.1 2.2-16.6 9-27.8 16.3-34.2-57-6.4-116.5-28.5-116.5-126.4 0-27.8 9.9-50.9 26.2-68.8-2.6-6.4-11.5-32.6 2.6-67.8 0 0 21.4-6.7 70.4 26.2 20.5-5.8 42.2-8.6 64-8.6s43.5 2.9 64 8.6c49-33.3 70.4-26.2 70.4-26.2 14.1 35.2 5.1 61.4 2.6 67.8 16.3 17.9 26.2 40.6 26.2 68.8 0 98.2-59.8 120-116.8 126.4 9.3 8 17.3 23.4 17.3 47.4 0 34.2-.3 61.8-.3 70.4 0 6.7 4.8 14.7 17.6 12.2C438.7 471.3 512 375.3 512 262.3c0-141.4-114.6-256-256-256"
      style="fill-rule:evenodd;clip-rule:evenodd;fill:currentColor"
    />
    """
  end

  defp path_for("twitter") do
    """
    <path
      d="M459.6 151.6c.3 4.5.3 9 .3 13.6C459.9 303.9 354.2 464 161 464v-.1c-57.1.1-113-16.2-161-47.1 8.3 1 16.6 1.5 25 1.5 47.3 0 93.2-15.8 130.5-45.1-44.9-.9-84.4-30.2-98.1-72.9 15.7 3 32 2.4 47.4-1.8-49-9.9-84.3-53-84.3-103v-1.3c14.6 8.1 31 12.6 47.7 13.1C22 176.6 7.8 115.2 35.7 67.1c53.3 65.6 132 105.5 216.5 109.7-8.5-36.5 3.1-74.7 30.4-100.4 42.3-39.8 108.8-37.7 148.6 4.6 23.5-4.6 46.1-13.3 66.7-25.5-7.8 24.3-24.3 45-46.2 58.1 20.8-2.5 41.2-8 60.3-16.5-14.1 21.2-31.9 39.6-52.4 54.5"
      style="fill:currentColor"
    />
    """
  end

  defp path_for("bluesky") do
    """
    <path
      d="M111 60.9c58.7 44.1 121.8 133.4 145 181.4 23.2-47.9 86.3-137.3 145-181.4 42.4-31.8 111-56.4 111 21.9 0 15.6-9 131.3-14.2 150.1-18.3 65.3-84.9 82-144.1 71.9 103.5 17.6 129.9 76 73 134.4-108 110.9-155.3-27.8-167.4-63.4-2.2-6.5-3.3-9.6-3.3-7 0-2.6-1.1.5-3.3 7-12.1 35.5-59.4 174.2-167.4 63.4-56.9-58.4-30.5-116.8 73-134.4-59.2 10.1-125.8-6.5-144.1-71.8C9 214.2 0 98.5 0 82.8 0 4.5 68.6 29.1 111 60.9"
      style="fill:currentColor"
    />
    """
  end

  defp path_for("linkedin") do
    """
    <path
      d="M455.1 0H56.9C25.5 0 0 25.5 0 56.9v398.2C0 486.5 25.5 512 56.9 512h398.2c31.4 0 56.9-25.5 56.9-56.9V56.9C512 25.5 486.5 0 455.1 0M154.8 440.9H78.5V194.4h76.4v246.5zm-38.5-278.8c-24.9 0-45.2-20.4-45.2-45.5s20.2-45.5 45.2-45.5 45.1 20.4 45.1 45.5-20.2 45.5-45.1 45.5m324.6 278.8h-76V311.5c0-35.5-13.5-55.3-41.6-55.3-30.5 0-46.5 20.6-46.5 55.3v129.4h-73.2V194.4h73.2v33.2s22-40.7 74.3-40.7 89.7 31.9 89.7 98v156z"
      style="fill-rule:evenodd;clip-rule:evenodd;fill:currentColor"
    />
    """
  end

  defp path_for("tangled") do
    """
    <path d="M21.0971 30.866C20.0566 30.8575 19.2628 30.5542 18.4016 30.0269C17.1668 29.3753 16.2237 28.2808 15.5497 27.0739C14.4789 28.4065 13.0476 29.215 11.4453 29.6718C10.763 29.8705 9.56809 30.0721 7.58737 29.3523C4.73277 28.3905 2.65342 25.4114 2.88973 22.3758C2.8465 21.1175 3.30392 19.8825 3.95228 18.8208C2.22264 17.8897 0.81225 16.3266 0.272148 14.4098C-0.0560731 13.3604 -0.042271 12.2299 0.0787626 11.1512C0.512215 8.60429 2.41697 6.38956 4.86912 5.59294C5.8479 3.35574 7.98378 1.68743 10.4037 1.34778C12.0104 1.12338 13.6735 1.46075 15.0792 2.27979C17.1272 0.00158595 20.6952 -0.671697 23.4195 0.727793C25.4978 1.72322 26.9839 3.80003 27.3447 6.06471C29.3222 6.85928 30.9877 8.47971 31.6413 10.5368C32.0784 11.8104 32.0928 13.2132 31.8098 14.5209C31.3041 16.5615 29.8679 18.2987 28.009 19.2482C28.0135 19.6113 29.2037 22.2296 29.0047 24.2056C28.9612 26.676 27.399 29.0172 25.2325 30.1544C23.9683 30.8945 22.4702 30.8805 21.0971 30.866ZM15.1733 23.755C16.9256 23.5593 18.0743 22.0269 18.9665 20.6469C19.3883 20.0182 19.7105 19.3146 20.0306 18.6454C20.4458 19.0271 20.7975 19.7461 21.4541 19.9173C22.1457 20.1333 22.9566 19.9579 23.38 19.3277C24.1902 17.8118 23.7908 15.9827 23.319 14.4119C23.0284 13.5097 22.6472 12.5841 21.9218 11.9446C22.0765 10.85 21.4299 9.73834 20.5106 9.16542C19.7272 9.79198 18.5352 9.78821 17.7794 9.11795C16.3309 10.5997 15.0034 10.5505 13.7212 9.37618C13.4331 9.11226 12.8832 10.9871 10.9535 9.92506C9.84488 10.8567 8.98526 11.753 8.22356 13.0435C7.48342 14.4347 6.70829 15.6703 6.64151 17.1811C6.6094 18.0641 7.29731 18.9892 8.22942 18.9174C9.16105 19.0009 9.7952 18.0813 10.5006 17.6993C10.6058 18.9316 10.7243 20.2556 11.1395 21.4587C11.6161 23.0155 13.2947 24.005 14.8835 23.7784C14.9959 23.7696 15.1733 23.7549 15.1733 23.755ZM16.0828 19.1062C15.2306 18.5823 15.6407 17.4452 15.6066 16.6193C15.6914 15.6227 15.7594 14.575 16.2061 13.667C16.6788 13.0197 17.8318 13.2694 17.8827 14.0999C17.8488 14.9353 17.4664 15.767 17.5121 16.633C17.4129 17.3561 17.5839 18.1684 17.265 18.8293C17.0033 19.195 16.4703 19.3013 16.0828 19.1062ZM12.3606 18.6302C11.5578 18.1933 11.8129 17.0941 11.687 16.3298C11.7914 15.445 11.7045 14.3226 12.4431 13.7021C13.1653 13.1969 14.1485 14.0621 13.8069 14.8564C13.4426 15.8602 13.6814 16.957 13.6891 17.9748C13.5512 18.5752 12.911 18.894 12.3606 18.6302Z"
    style="fill-rule:evenodd;clip-rule:evenodd;fill:currentColor" transform="scale(16)"
    />
    """
  end

  @doc """
  Renders a heading with responsive sizing and consistent margins.

  ## Examples

      <.heading level={1}>Welcome to My Blog</.heading>
      <.heading level={2}>Latest Posts</.heading>
  """
  attr :level, :integer, values: [1, 2, 3, 4], default: 1
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def heading(assigns) do
    ~H"""
    <h1
      :if={@level == 1}
      class={[
        "text-4xl md:text-5xl lg:text-6xl font-semibold tracking-tight text-foreground",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </h1>
    <h2
      :if={@level == 2}
      class={[
        "text-3xl md:text-4xl font-semibold tracking-tight text-foreground",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </h2>
    <h3
      :if={@level == 3}
      class={[
        "text-2xl md:text-3xl font-semibold tracking-tight text-foreground",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </h3>
    <h4
      :if={@level == 4}
      class={[
        "text-xl md:text-2xl font-semibold tracking-tight text-foreground",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </h4>
    """
  end

  @doc """
  Renders text with variant-based styling.

  ## Examples

      <.text>Regular body text</.text>
      <.text variant={:lead}>Leading paragraph text</.text>
      <.text variant={:muted}>Secondary information</.text>
  """
  attr :variant, :atom, values: [:default, :lead, :muted], default: :default
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def text(assigns) do
    ~H"""
    <p class={[
      @variant == :default && "text-base text-foreground",
      @variant == :lead && "text-lg md:text-xl text-foreground",
      @variant == :muted && "text-sm text-muted-foreground",
      @class
    ]}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a versatile card container.

  ## Examples

      <.card>
        Default card content
      </.card>

      <.card variant={:bordered} hover>
        Interactive bordered card
      </.card>
  """
  attr :variant, :atom, values: [:default, :bordered, :interactive], default: :default
  attr :hover, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "rounded-lg p-6 md:p-8",
      @variant == :default && "",
      @variant == :bordered && "border border-border",
      @variant == :interactive && "border border-border cursor-pointer transition-all",
      @hover && "hover:bg-surface/50",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :author, :string, required: true
  attr :class, :string, default: nil

  def author(assigns) do
    ~H"""
    <p class={[
      "mt-16 pt-8 border-t border-border text-muted-foreground",
      @class
    ]}>
      Written by <.link href="/about" class="underline text-foreground">{@author}</.link>.
      Thoughts on this post? Find me on Bluesky at
      <.link
        href="https://bsky.app/profile/jola.dev"
        class="underline text-foreground"
      >
        @jola.dev
      </.link>
      .
    </p>
    """
  end

  attr :title, :string, required: true
  attr :class, :string, default: nil

  def sponsor(assigns) do
    ~H"""
    <aside class={["mt-8", @class]}>
      <div class="rounded-lg border border-accent/30 bg-accent/5 p-6 md:p-8">
        <p class="text-lg font-semibold text-foreground mb-2">
          {assigns.title}
        </p>
        <p class="text-muted-foreground mb-5">
          Support my writing on GitHub Sponsors and get a monthly newsletter with content from the blog, or buy me a coffee on Ko-fi.
        </p>
        <div class="flex items-center gap-6">
          <script type="text/javascript" src="https://storage.ko-fi.com/cdn/widget/Widget_2.js">
          </script>
          <script type="text/javascript">
            kofiwidget2.init('Support me on Ko-fi', '#72a4f2', 'S7V820WQ7W');kofiwidget2.draw();
          </script>

          <.link
            href="https://github.com/sponsors/joladev"
            class="inline-flex items-center gap-2 rounded-lg bg-accent px-4 py-2 text-sm leading-6 font-medium text-white transition-opacity hover:opacity-90 "
          >
            ❤️ Sponsor me on GitHub
          </.link>
        </div>
      </div>
    </aside>
    """
  end

  @doc """
  Renders the site navigation.

  ## Examples

      <.navigation theme_toggle social_links>
        <:link href="/">About</:link>
        <:link href="/blog">Blog</:link>
        <:link href="/projects">Projects</:link>
      </.navigation>
  """
  attr :social_links, :boolean, default: true
  attr :class, :string, default: nil

  slot :link do
    attr :href, :string, required: true
    attr :active, :boolean
  end

  def navigation(assigns) do
    ~H"""
    <nav class={["w-full", @class]}>
      <div class="max-w-content mx-auto px-6 md:px-8">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center space-x-8">
            <.link
              href="/"
              class="flex items-center gap-2 text-xl font-semibold text-foreground hover:opacity-80 transition-opacity font-heading"
            >
              <.icon name="lucide-terminal" class="w-6 h-6 text-accent" /> jola.dev
            </.link>

            <div class="hidden md:flex items-center space-x-6">
              <.link
                :for={link <- @link}
                href={link.href}
                class={[
                  "text-sm font-medium transition-all relative group",
                  link[:active] && "text-foreground",
                  !link[:active] && "text-muted-foreground hover:text-foreground"
                ]}
              >
                {render_slot(link)}
                <span class={[
                  "absolute -bottom-1 left-0 h-0.5 bg-accent transition-all",
                  link[:active] && "w-full",
                  !link[:active] && "w-0 group-hover:w-full"
                ]}></span>
              </.link>
            </div>
          </div>

          <div class="flex items-center space-x-4">
            <div :if={@social_links} class="hidden md:flex items-center space-x-2">
              <a
                href="https://tangled.org/jola.dev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="Tangled"
              >
                <.brand_icon name="tangled" class="w-5 h-5" />
              </a>
              <a
                href="https://github.com/joladev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="GitHub"
              >
                <.brand_icon name="github" class="w-5 h-5" />
              </a>
              <a
                href="https://twitter.com/joladev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="Twitter"
              >
                <.brand_icon name="twitter" class="w-5 h-5" />
              </a>
              <a
                href="https://bsky.app/profile/jola.dev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="Bluesky"
              >
                <.brand_icon name="bluesky" class="w-5 h-5" />
              </a>
              <a
                href="https://linkedin.com/in/joladev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="LinkedIn"
              >
                <.brand_icon name="linkedin" class="w-5 h-5" />
              </a>
              <a
                href="/rss.xml"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="RSS Feed"
              >
                <.icon name="lucide-rss" class="w-5 h-5" />
              </a>
            </div>

            <button
              data-mobile-menu-button
              aria-expanded="false"
              aria-controls="mobile-menu"
              aria-label="Toggle menu"
              class="md:hidden flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
            >
              <.icon name="lucide-menu" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </nav>

    <div id="mobile-menu" data-mobile-menu class="mobile-menu bg-background">
      <div class="px-6 py-4 space-y-2">
        <.link
          :for={link <- @link}
          href={link.href}
          class={[
            "block px-3 py-2 text-base font-medium rounded-lg transition-colors",
            link[:active] && "bg-surface text-foreground",
            !link[:active] && "text-muted-foreground hover:text-foreground hover:bg-surface"
          ]}
        >
          {render_slot(link)}
        </.link>

        <div :if={@social_links} class="pt-4 border-t border-border">
          <div class="flex items-center space-x-2 flex-nowrap">
            <a
              href="https://tangled.org/jola.dev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Tangled"
            >
              <.brand_icon name="tangled" class="w-5 h-5" />
            </a>
            <a
              href="https://github.com/joladev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="GitHub"
            >
              <.brand_icon name="github" class="w-5 h-5" />
            </a>
            <a
              href="https://twitter.com/joladev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Twitter"
            >
              <.brand_icon name="twitter" class="w-5 h-5" />
            </a>
            <a
              href="https://bsky.app/profile/jola.dev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Bluesky"
            >
              <.brand_icon name="bluesky" class="w-5 h-5" />
            </a>
            <a
              href="https://linkedin.com/in/joladev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="LinkedIn"
            >
              <.brand_icon name="linkedin" class="w-5 h-5" />
            </a>
            <a
              href="/rss.xml"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="RSS Feed"
            >
              <.icon name="lucide-rss" class="w-5 h-5" />
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a minimal footer.

  ## Examples

      <.footer tagline="Building software with care" />
  """
  attr :tagline, :string, default: nil
  attr :class, :string, default: nil

  def footer(assigns) do
    ~H"""
    <footer class={["mt-auto border-t border-border", @class]}>
      <div class="max-w-content mx-auto px-6 md:px-8 py-8">
        <div class="flex flex-col md:flex-row items-center justify-between space-y-4 md:space-y-0">
          <div class="text-center md:text-left">
            <p :if={@tagline} class="text-sm text-muted-foreground mb-1">
              {@tagline}
            </p>
            <p class="text-xs text-muted-foreground">
              © {DateTime.utc_now().year} Johanna Larsson. All rights reserved.
            </p>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  @doc """
  Renders a blog post card.

  ## Examples

      <.blog_post_card
        title="Getting Started with Elixir"
        date="2024-01-15"
        reading_time={5}
        excerpt="Learn the basics of Elixir..."
        link="/blog/getting-started-with-elixir"
      />
  """
  attr :title, :string, required: true
  attr :date, :string, required: true
  attr :reading_time, :integer, default: nil
  attr :excerpt, :string, default: nil
  attr :link, :string, required: true
  attr :tags, :list, default: []
  attr :class, :string, default: nil

  def blog_post_card(assigns) do
    ~H"""
    <.link href={@link} class={["block group", @class]}>
      <.card variant={:bordered} hover class="h-full">
        <article>
          <div class="flex items-center gap-4 text-sm text-muted-foreground mb-3">
            <div class="flex items-center gap-1.5">
              <.icon name="hero-calendar" class="w-4 h-4" />
              <time>{@date}</time>
            </div>
            <div :if={@reading_time} class="flex items-center gap-1.5">
              <.icon name="hero-clock" class="w-4 h-4" />
              <span>{@reading_time} min read</span>
            </div>
          </div>

          <h3 class="text-xl font-semibold text-foreground mb-2 group-hover:text-foreground/80 transition-colors">
            {@title}
          </h3>

          <p :if={@excerpt} class="text-muted-foreground line-clamp-3 mb-4">
            {@excerpt}
          </p>

          <div :if={@tags != []} class="flex flex-wrap gap-2">
            <.badge :for={tag <- @tags} variant={:muted}>
              {tag}
            </.badge>
          </div>
        </article>
      </.card>
    </.link>
    """
  end

  @doc """
  Renders a project card.

  ## Examples

      <.project_card
        title="Phoenix App"
        description="A web application built with Phoenix"
        tags={["Elixir", "Phoenix", "PostgreSQL"]}
        link="https://github.com/user/project"
      />
  """
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :tags, :list, default: []
  attr :link, :string, default: nil
  attr :github_link, :string, default: nil
  attr :external, :boolean, default: true
  attr :class, :string, default: nil

  def project_card(assigns) do
    # Determine the primary link (prefer external link over github)
    assigns = assign(assigns, :primary_link, assigns[:link] || assigns[:github_link])

    ~H"""
    <a
      href={@primary_link || "#"}
      target={if @external && @primary_link, do: "_blank"}
      rel={if @external && @primary_link, do: "noopener"}
      class={["block group", @class]}
    >
      <.card variant={:interactive} hover class="h-full">
        <div class="flex items-start justify-between mb-3">
          <h3 class="text-xl font-semibold text-foreground group-hover:text-foreground/80 transition-colors">
            {@title}
          </h3>
          <div class="flex items-center gap-0 flex-shrink-0 ml-2">
            <span
              :if={@github_link}
              onclick={"event.stopPropagation(); event.preventDefault(); window.open('#{@github_link}', '_blank');"}
              class="text-muted-foreground hover:text-foreground transition-colors cursor-pointer relative z-10 inline-flex size-8 items-center justify-center"
              aria-label="View on GitHub"
            >
              <.brand_icon name="github" class="w-4 h-4" />
            </span>
            <span
              :if={@link}
              class="text-muted-foreground hover:text-foreground transition-colors inline-flex size-8 items-center justify-center"
              aria-label="Visit project"
            >
              <.icon
                name={if @external, do: "hero-arrow-top-right-on-square", else: "hero-arrow-right"}
                class="w-4 h-4"
              />
            </span>
          </div>
        </div>

        <p :if={@description} class="text-muted-foreground mb-4">
          {@description}
        </p>

        <div :if={@tags != []} class="flex flex-wrap gap-2">
          <.badge :for={tag <- @tags} variant={:default}>
            {tag}
          </.badge>
        </div>
      </.card>
    </a>
    """
  end

  @doc """
  Renders a blog post card.

  ## Examples

      <.blog_card
        post={@post}
        class="custom-class"
      />
  """
  attr :post, :map, required: true
  attr :class, :string, default: nil

  def blog_card(assigns) do
    ~H"""
    <.link href={"/posts/#{@post.id}"} class={["block group", @class]}>
      <.card variant={:interactive} hover class="h-full">
        <div class="mb-3">
          <h3 class="text-xl font-semibold text-foreground group-hover:text-foreground/80 transition-colors mb-2">
            {@post.title}
          </h3>
          <time class="text-sm text-muted-foreground">
            {Calendar.strftime(@post.date, "%B %d, %Y")}
          </time>
        </div>

        <p class="text-muted-foreground mb-4 line-clamp-3">
          {@post.description}
        </p>

        <div class="flex items-center justify-between">
          <div class="flex flex-wrap gap-2">
            <.badge :for={tag <- Enum.take(@post.tags, 2)} variant={:default}>
              {tag}
            </.badge>
          </div>
          <.icon
            name="hero-arrow-right"
            class="w-5 h-5 text-muted-foreground group-hover:text-foreground transition-colors flex-shrink-0"
          />
        </div>
      </.card>
    </.link>
    """
  end

  @doc """
  Renders a video card for talks/presentations.

  ## Examples

      <.video_card
        title="Building Scalable Apps with Elixir"
        conference="ElixirConf"
        year="2024"
        video_id="dQw4w9WgXcQ"
        description="Learn how to build..."
      />
  """
  attr :title, :string, required: true
  attr :conference, :string, default: nil
  attr :year, :string, default: nil
  attr :video_id, :string, required: true
  attr :description, :string, default: nil
  attr :class, :string, default: nil

  def video_card(assigns) do
    ~H"""
    <div class={["group", @class]}>
      <.card variant={:bordered} class="overflow-hidden">
        <div class="relative aspect-video bg-surface rounded-lg overflow-hidden mb-4">
          <img
            src={"https://img.youtube.com/vi/#{@video_id}/hqdefault.jpg"}
            alt={@title}
            width="480"
            height="360"
            class="w-full h-full object-cover"
            loading="lazy"
            decoding="async"
          />
          <div class="absolute inset-0 flex items-center justify-center bg-background/60 group-hover:bg-background/50 transition-colors">
            <div class="w-16 h-16 bg-foreground/90 rounded-full flex items-center justify-center group-hover:scale-110 transition-transform">
              <.icon name="hero-play-solid" class="w-8 h-8 text-background ml-1" />
            </div>
          </div>
        </div>

        <h3 class="text-xl font-semibold text-foreground mb-2">
          {@title}
        </h3>

        <div
          :if={@conference || @year}
          class="flex items-center gap-2 text-sm text-muted-foreground mb-3"
        >
          <span :if={@conference}>{@conference}</span>
          <span :if={@conference && @year}>•</span>
          <span :if={@year}>{@year}</span>
        </div>

        <p :if={@description} class="text-muted-foreground">
          {@description}
        </p>
      </.card>
    </div>
    """
  end

  attr :url, :string, required: true

  def bubbles_vote(assigns) do
    ~H"""
    <div id="vote-on-bubbles" data-url={@url} class="mt-2" />
    """
  end
end
