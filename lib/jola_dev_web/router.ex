defmodule JolaDevWeb.Router do
  use JolaDevWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JolaDevWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :rss do
    plug :accepts, ["xml"]
    plug :put_layout, false
  end

  scope "/", JolaDevWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/about", PageController, :about
    get "/projects", PageController, :projects
    get "/talks", PageController, :talks
    get "/posts", BlogController, :index
    get "/posts/:id", BlogController, :show
  end

  scope "/", JolaDevWeb do
    pipe_through :rss

    get "/rss.xml", RssController, :index
    get "/feed.xml", RssController, :index
    get "/sitemap.xml", SitemapController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", JolaDevWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
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
