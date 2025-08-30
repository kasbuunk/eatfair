defmodule EatfairWeb.UserLive.AccountSetup do
  use EatfairWeb, :live_view

  alias Eatfair.Accounts
  alias Eatfair.Orders

  def mount(_params, session, socket) do
    user = socket.assigns.current_scope.user

    # Get order context from session if available
    post_verify_order_id = session["post_verify_order_id"]

    # Only show account setup for users without passwords
    if user.hashed_password do
      # User already has password, redirect to appropriate location
      redirect_path = determine_redirect_path(user.id, post_verify_order_id)

      socket =
        socket
        |> put_flash(:info, "Your account is already set up.")
        |> push_navigate(to: redirect_path)

      {:ok, socket}
    else
      changeset = Accounts.change_user_password(user, %{}, hash_password: false)

      {:ok,
       socket
       |> assign(:page_title, "Complete Account Setup")
       |> assign(:form, to_form(changeset))
       |> assign(:marketing_opt_in, false)
       |> assign(:terms_accepted, false)
       |> assign(:trigger_submit, false)
       |> assign(:post_verify_order_id, post_verify_order_id)}
    end
  end

  def handle_event("validate", %{"user" => user_params} = params, socket) do
    form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:marketing_opt_in, params["marketing_opt_in"] == "true")
     |> assign(:terms_accepted, params["terms_accepted"] == "true")}
  end

  def handle_event("save", %{"user" => user_params} = params, socket) do
    marketing_opt_in = params["marketing_opt_in"] == "true"
    terms_accepted = params["terms_accepted"] == "true"
    user = socket.assigns.current_scope.user

    # Validate terms acceptance (required for save path)
    if not terms_accepted do
      {:noreply,
       socket
       |> put_flash(:error, "You must accept the Terms and Conditions to continue.")
       |> assign(:terms_accepted, false)}
    else
      # Update password if provided (allow blank for passwordless accounts)
      password_result =
        if user_params["password"] != "" do
          Accounts.update_user_password(user, user_params)
        else
          {:ok, {user, []}}
        end

      case password_result do
        {:ok, {_updated_user, _tokens}} ->
          # TODO: Store marketing opt-in preference

          redirect_path = determine_redirect_path(user.id, socket.assigns.post_verify_order_id)

          {:noreply,
           socket
           |> put_flash(:info, "Account setup completed successfully!")
           |> push_navigate(to: redirect_path)}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(:form, to_form(changeset))
           |> assign(:marketing_opt_in, marketing_opt_in)
           |> assign(:terms_accepted, terms_accepted)}
      end
    end
  end

  def handle_event("skip", _params, socket) do
    user = socket.assigns.current_scope.user
    redirect_path = determine_redirect_path(user.id, socket.assigns.post_verify_order_id)

    {:noreply,
     socket
     |> put_flash(:info, "Welcome! You can set up your password later in settings.")
     |> push_navigate(to: redirect_path)}
  end

  # Private helper to determine where to redirect after account setup
  defp determine_redirect_path(user_id, post_verify_order_id) do
    cond do
      # If we have a specific order from email verification, redirect to it
      post_verify_order_id ->
        try do
          order = Orders.get_order!(post_verify_order_id)
          ~p"/orders/#{order.id}/track?token=#{order.tracking_token}"
        rescue
          # Fallback to general tracking
          _ -> ~p"/orders/track"
        end

      # Otherwise, find user's latest order and redirect to it
      user_id ->
        case Orders.get_latest_customer_order(user_id) do
          %Orders.Order{} = order ->
            ~p"/orders/#{order.id}/track?token=#{order.tracking_token}"

          nil ->
            # Fallback to general tracking page
            ~p"/orders/track"
        end

      # Final fallback
      true ->
        ~p"/orders/track"
    end
  end
end
