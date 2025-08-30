defmodule EatfairWeb.Router do
  use EatfairWeb, :router

  import EatfairWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EatfairWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug EatfairWeb.Plugs.Observability
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EatfairWeb do
    pipe_through :browser

    live_session :current_user,
      on_mount: [{EatfairWeb.UserAuth, :mount_current_scope}] do
      live "/", RestaurantLive.Index, :index
      live "/restaurants", RestaurantLive.Discovery, :index
      live "/restaurants/:id", RestaurantLive.Show, :show
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new

      # Streamlined ordering flow - no authentication required
      live "/order/:restaurant_id/details", OrderLive.Details, :details
      live "/order/:restaurant_id/confirm", OrderLive.Confirm, :confirm
      live "/order/:restaurant_id/payment", OrderLive.Payment, :payment
      live "/order/success/:id", OrderLive.Success, :success

      # Anonymous order tracking - accessible via email links
      live "/orders/:id/track", OrderTrackingLive, :anonymous_show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", EatfairWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:eatfair, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EatfairWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    # Admin routes - secured with basic auth for development
    scope "/admin" do
      pipe_through [:browser, :admin_auth]

      live "/feedback", EatfairWeb.Admin.FeedbackDashboardLive, :index
    end
  end

  # Basic auth for admin routes in development
  if Application.compile_env(:eatfair, :dev_routes) do
    defp admin_auth(conn, _opts) do
      username = System.get_env("ADMIN_USERNAME") || "admin"
      password = System.get_env("ADMIN_PASSWORD") || "admin123"

      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    end
  end

  ## Authentication routes

  scope "/", EatfairWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{EatfairWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/users/addresses", UserLive.Addresses, :index
      live "/checkout/:restaurant_id", CheckoutLive, :index

      # Order tracking - for customers
      live "/orders/track", OrderTrackingLive, :index
      live "/orders/track/:id", OrderTrackingLive, :show

      # Restaurant onboarding - available to all authenticated users
      live "/restaurant/onboard", RestaurantLive.Onboarding, :new
    end

    # Admin routes - requires admin role
    live_session :require_admin,
      on_mount: [{EatfairWeb.UserAuth, :require_admin}] do
      live "/admin", Admin.DashboardLive, :index
      live "/admin/dashboard", Admin.DashboardLive, :index
      live "/admin/users", Admin.UsersLive, :index
      live "/admin/feedback", Admin.FeedbackDashboardLive, :index
    end

    # Restaurant management - requires restaurant ownership
    live_session :require_restaurant_owner,
      on_mount: [{EatfairWeb.UserAuth, :require_authenticated}] do
      live "/restaurant/dashboard", RestaurantLive.Dashboard, :index
      live "/restaurant/profile/edit", RestaurantLive.ProfileEdit, :edit

      # Menu management routes
      live "/restaurant/menu", MenuLive.Management, :index
      live "/restaurant/menu/preview", MenuLive.Preview, :preview

      # Order management for restaurants
      live "/restaurant/orders", RestaurantOrderManagementLive, :index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", EatfairWeb do
    pipe_through [:browser]

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete

    # Email verification route - no authentication required
    get "/verify-email/:token", EmailVerificationController, :verify
  end
end
