defmodule JolaDevWeb.Router do
  use JolaDevWeb, :router

  @secure_headers %{
    "strict-transport-security" => "max-age=63072000; includeSubDomains",
    "referrer-policy" => "strict-origin-when-cross-origin",
    "permissions-policy" => "camera=(), microphone=(), geolocation=()"
  }

  pipeline :public do
    plug :accepts, ["html"]
    plug :put_root_layout, html: {JolaDevWeb.Layouts, :root}
    plug :put_secure_browser_headers, @secure_headers
    plug :put_cdn_cache_header
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JolaDevWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, @secure_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :rss do
    plug :accepts, ["xml"]
    plug :put_layout, false
  end

  scope "/", JolaDevWeb do
    pipe_through :public

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/projects", PageController, :projects
    get "/talks", PageController, :talks
    get "/posts", BlogController, :index
    get "/posts/tag/:tag", BlogController, :tag
    get "/posts/:id", BlogController, :show
  end

  scope "/", JolaDevWeb do
    pipe_through :rss

    get "/rss.xml", RssController, :index
    get "/feed.xml", RssController, :index
    get "/sitemap.xml", SitemapController, :index
  end

  scope "/", JolaDevWeb do
    get "/llms.txt", LlmsController, :index
    get "/llms-full.txt", LlmsController, :full
  end

  # Other scopes may use custom stacks.
  # scope "/api", JolaDevWeb do
  #   pipe_through :api
  # end

  defp put_cdn_cache_header(conn, _opts) do
    put_resp_header(conn, "cache-control", "public, s-maxage=86400, max-age=0")
  end

  if Application.compile_env(:jola_dev, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JolaDevWeb.Telemetry
    end
  end
end
