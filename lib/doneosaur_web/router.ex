defmodule DoneosaurWeb.Router do
  use DoneosaurWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DoneosaurWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DoneosaurWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/clients/:name", ClientLive
    live "/lists/:id", TaskListLive
  end

  scope "/admin", DoneosaurWeb.Admin do
    pipe_through :browser

    live "/", IndexLive
    live "/lists/new", FormLive, :new
    live "/lists/:id/edit", FormLive, :edit
  end

  # API routes
  scope "/api", DoneosaurWeb do
    pipe_through :api

    post "/lists/activate", ListController, :activate
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:doneosaur, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DoneosaurWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
