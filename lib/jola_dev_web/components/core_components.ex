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

  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

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
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
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

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(JolaDevWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(JolaDevWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  ## New Design System Components

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
  Renders inline code with surface background.

  ## Examples

      <.inline_code>mix phx.server</.inline_code>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def inline_code(assigns) do
    ~H"""
    <code class={["bg-surface px-1.5 py-0.5 rounded text-sm font-mono", @class]}>
      {render_slot(@inner_block)}
    </code>
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
      @hover && "hover:bg-surface/50 hover:-translate-y-0.5 transition-all duration-200",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
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
              class="flex items-center gap-2 text-xl font-semibold text-foreground hover:opacity-80 transition-opacity"
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
                ]}>
                </span>
              </.link>
            </div>
          </div>

          <div class="flex items-center space-x-4">
            <div :if={@social_links} class="hidden md:flex items-center space-x-2">
              <a
                href="https://github.com/joladev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="GitHub"
              >
                <.icon name="lucide-github" class="w-5 h-5" />
              </a>
              <a
                href="https://twitter.com/joladev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="Twitter"
              >
                <.icon name="lucide-x" class="w-5 h-5" />
              </a>
              <a
                href="https://bsky.app/profile/jola.dev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="Bluesky"
              >
                <.icon name="lucide-cloud" class="w-5 h-5" />
              </a>
              <a
                href="https://linkedin.com/in/joladev"
                target="_blank"
                rel="noopener"
                class="flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-surface transition-all"
                aria-label="LinkedIn"
              >
                <.icon name="lucide-linkedin" class="w-5 h-5" />
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
          <div class="flex items-center space-x-2">
            <a
              href="https://github.com/joladev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="GitHub"
            >
              <.icon name="lucide-github" class="w-5 h-5" />
            </a>
            <a
              href="https://twitter.com/joladev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Twitter"
            >
              <.icon name="lucide-x" class="w-5 h-5" />
            </a>
            <a
              href="https://bsky.app/profile/jola.dev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Bluesky"
            >
              <.icon name="lucide-cloud" class="w-5 h-5" />
            </a>
            <a
              href="https://linkedin.com/in/joladev"
              target="_blank"
              rel="noopener"
              class="text-muted-foreground hover:text-foreground transition-colors"
              aria-label="LinkedIn"
            >
              <.icon name="lucide-linkedin" class="w-5 h-5" />
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

      <.footer tagline="Building software with care">
        <:link href="https://github.com/jola">GitHub</:link>
        <:link href="https://twitter.com/joladev">Twitter</:link>
      </.footer>
  """
  attr :tagline, :string, default: nil
  attr :class, :string, default: nil

  slot :link do
    attr :href, :string, required: true
  end

  def footer(assigns) do
    ~H"""
    <footer class={["mt-auto border-t border-border", @class]}>
      <div class="max-w-content mx-auto px-6 md:px-8 py-8">
        <div class="flex flex-col md:flex-row items-center justify-between space-y-4 md:space-y-0">
          <div class="text-center md:text-left">
            <p :if={@tagline} class="text-sm text-muted-foreground mb-1">
              {@tagline}
            </p>
            <p class="text-xs text-muted">
              © {DateTime.utc_now().year} Johanna Larsson. All rights reserved.
            </p>
          </div>

          <div :if={@link != []} class="flex items-center space-x-6">
            <.link
              :for={link <- @link}
              href={link.href}
              target="_blank"
              rel="noopener"
              class="text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              {render_slot(link)}
            </.link>
          </div>
        </div>
      </div>
    </footer>
    """
  end

  @doc """
  Renders a hero section.

  ## Examples

      <.hero 
        title="Welcome to My Blog" 
        subtitle="Software Engineer & Writer"
        description="Building things that matter"
        badge="Available for consulting"
        primary_action={%{label: "View Work", href: "/projects"}}
        secondary_action={%{label: "Get in Touch", href: "/contact"}}
      />
  """
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :description, :string, default: nil
  attr :badge, :string, default: nil
  attr :primary_action, :map, default: nil
  attr :secondary_action, :map, default: nil
  attr :class, :string, default: nil

  def hero(assigns) do
    ~H"""
    <section class={["py-20 md:py-32", @class]}>
      <div class="max-w-prose mx-auto px-6 md:px-8 text-center">
        <.badge :if={@badge} variant={:success} dot class="mb-4">
          {@badge}
        </.badge>

        <h1 class="text-5xl md:text-6xl lg:text-7xl font-semibold tracking-tight text-foreground mb-4">
          {@title}
        </h1>

        <p :if={@subtitle} class="text-xl md:text-2xl text-muted-foreground mb-2">
          {@subtitle}
        </p>

        <p :if={@description} class="text-lg text-muted mb-8">
          {@description}
        </p>

        <div
          :if={@primary_action || @secondary_action}
          class="flex flex-col sm:flex-row gap-4 justify-center"
        >
          <.link :if={@primary_action} href={@primary_action.href}>
            <.button size={:lg}>
              {@primary_action.label}
            </.button>
          </.link>

          <.link :if={@secondary_action} href={@secondary_action.href}>
            <.button variant={:secondary} size={:lg}>
              {@secondary_action.label}
            </.button>
          </.link>
        </div>
      </div>
    </section>
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
          <div class="flex items-center gap-2 flex-shrink-0 ml-2">
            <span
              :if={@github_link}
              onclick={"event.stopPropagation(); event.preventDefault(); window.open('#{@github_link}', '_blank');"}
              class="text-muted-foreground hover:text-foreground transition-colors cursor-pointer relative z-10 p-2 -m-2"
              aria-label="View on GitHub"
            >
              <.icon name="lucide-github" class="w-5 h-5" />
            </span>
            <span
              :if={@link}
              class="text-muted-foreground group-hover:text-foreground transition-colors"
              aria-label="Visit project"
            >
              <.icon
                name={if @external, do: "hero-arrow-top-right-on-square", else: "hero-arrow-right"}
                class="w-5 h-5"
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
            src={"https://img.youtube.com/vi/#{@video_id}/maxresdefault.jpg"}
            alt={@title}
            class="w-full h-full object-cover"
            loading="lazy"
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

  @doc """
  Renders social media links.

  ## Examples

      <.social_links 
        links={[
          %{platform: "github", href: "https://github.com/user", label: "GitHub"},
          %{platform: "twitter", href: "https://twitter.com/user", label: "Twitter"}
        ]}
        variant={:inline}
      />
  """
  attr :links, :list, required: true
  attr :variant, :atom, values: [:inline, :stacked], default: :inline
  attr :class, :string, default: nil

  def social_links(assigns) do
    ~H"""
    <div class={[
      "flex",
      @variant == :inline && "flex-row items-center gap-4",
      @variant == :stacked && "flex-col gap-3",
      @class
    ]}>
      <a
        :for={link <- @links}
        href={link.href}
        target="_blank"
        rel="noopener"
        class={[
          "transition-all",
          @variant == :inline && "text-muted-foreground hover:text-foreground",
          @variant == :stacked && "flex items-center gap-3 text-foreground hover:text-foreground/80"
        ]}
        aria-label={link.label}
      >
        <.icon
          name={social_icon(link.platform)}
          class={if @variant == :inline, do: "w-5 h-5", else: "w-5 h-5 text-muted-foreground"}
        />
        <span :if={@variant == :stacked} class="text-sm">
          {link.label}
        </span>
      </a>
    </div>
    """
  end

  defp social_icon("github"), do: "hero-code-bracket"
  defp social_icon("twitter"), do: "hero-chat-bubble-left"
  defp social_icon("linkedin"), do: "hero-briefcase"
  defp social_icon("bluesky"), do: "hero-cloud"
  defp social_icon(_), do: "hero-link"
end
