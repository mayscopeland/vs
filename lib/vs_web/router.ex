defmodule VsWeb.Router do
  use VsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug VsWeb.Plugs.SeasonContext
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", VsWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Season routes
    get "/leagues/add", SeasonController, :new
    post "/leagues/add", SeasonController, :create
    get "/leagues/:id", SeasonController, :show

    # Team routes
    get "/leagues/:season_id/teams/", TeamController, :redirect_to_team
    get "/leagues/:season_id/teams/:id", TeamController, :show
    get "/leagues/:season_id/teams/:id/edit", TeamController, :edit
    put "/leagues/:season_id/teams/:id", TeamController, :update
    patch "/leagues/:season_id/teams/:id", TeamController, :update

    # Player routes
    get "/leagues/:season_id/players", PlayerController, :list
    get "/leagues/:season_id/players/:id", PlayerController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", VsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:vs, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: VsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
