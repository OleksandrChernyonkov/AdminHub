defmodule MySuperAppWeb.Router do
  use MySuperAppWeb, :router

  import MySuperAppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MySuperAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MySuperAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/admin", MySuperAppWeb do
    pipe_through [:browser, :admin, :require_authenticated_user]

    live("/", AdminPage)
    live("/users", AdminPage)
    live("/tabs", Tabs)
    live("/acc", Acc)
    live("/menu", Menu)
    live("/form", Form)
    live("/formlive", FormLive)
    live("/users/:id/edit", UserEdit)
    live("/pages", PagesPage)
    live("/invited-users", InvitedUsers)
    live("/posts", PostsPage)
    live("/published_posts", PublishedPostsPage)
    live("/pictures", PicturesLive)
    live("/rows", RowPage)
  end

  scope "/admin", MySuperAppWeb do
    pipe_through [:browser, :admin, :require_authenticated_operator]

    live("/site-configs", SitesPage)
    live("/roles", RolesPage)
  end

  scope "/admin", MySuperAppWeb do
    pipe_through [:browser, :admin, :require_authenticated_super_admin]

    live("/operators", OperatorsPage)
  end

  scope "/", MySuperAppWeb do
    pipe_through :browser

    live("/", HomeLive)
    live("/tabs", Tabs)
    live("/acc", Acc)
    live("/menu", Menu)
    live("/form", Form)
    live("/formlive", FormLive)
    live("/users", UsersPage)
    live("/users/:id/edit", UserEdit)

    live_session :require_authenticated_user,
      on_mount: [{MySuperAppWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/api", MySuperAppWeb do
    pipe_through :api

    resources "/posts", PostController
    resources "/pictures", PictureController
    put "/pictures", PictureController, :update
    resources "/users", UserController
    resources "/roles", RoleController
    resources "/sites", SiteController
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:my_super_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MySuperAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", MySuperAppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MySuperAppWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MySuperAppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{MySuperAppWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
