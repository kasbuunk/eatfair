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
      # Get delivery address from order if available
      {delivery_address, invoice_address} = get_addresses_from_order(post_verify_order_id)

      # Create changesets for user and addresses
      user_changeset =
        Accounts.change_user_password(user, %{name: user.name || ""}, hash_password: false)

      delivery_changeset = Accounts.change_address(%Accounts.Address{}, delivery_address)
      invoice_changeset = Accounts.change_address(%Accounts.Address{}, invoice_address)

      {:ok,
       socket
       |> assign(:page_title, "Set Up Your Account")
       |> assign(:form, to_form(user_changeset))
       |> assign(:delivery_form, to_form(delivery_changeset))
       |> assign(:invoice_form, to_form(invoice_changeset))
       |> assign(:marketing_opt_in, false)
       |> assign(:terms_accepted, false)
       |> assign(:same_as_delivery, true)
       |> assign(:trigger_submit, false)
       |> assign(:post_verify_order_id, post_verify_order_id)}
    end
  end

  def handle_event("validate", params, socket) do
    # Extract parameters
    user_params = params["user"] || %{}
    delivery_params = params["delivery"] || %{}
    invoice_params = params["invoice"] || %{}
    # Handle checkbox: with hidden input, "false" means unchecked, "true" means checked
    same_as_delivery = params["same_as_delivery"] == "true"

    # Create validation changesets
    user_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    delivery_form =
      %Accounts.Address{}
      |> Accounts.change_address(delivery_params)
      |> Map.put(:action, :validate)
      |> to_form()

    # If same as delivery, copy delivery params to invoice
    final_invoice_params = if same_as_delivery, do: delivery_params, else: invoice_params

    invoice_form =
      %Accounts.Address{}
      |> Accounts.change_address(final_invoice_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(:form, user_form)
     |> assign(:delivery_form, delivery_form)
     |> assign(:invoice_form, invoice_form)
     |> assign(:marketing_opt_in, params["marketing_opt_in"] == "true")
     |> assign(:terms_accepted, params["terms_accepted"] == "true")
     |> assign(:same_as_delivery, same_as_delivery)}
  end

  def handle_event("save", params, socket) do
    # Extract all parameters
    user_params = params["user"] || %{}
    delivery_params = params["delivery"] || %{}
    invoice_params = params["invoice"] || %{}
    marketing_opt_in = params["marketing_opt_in"] == "true"
    terms_accepted = params["terms_accepted"] == "true"
    same_as_delivery = params["same_as_delivery"] == "true"
    user = socket.assigns.current_scope.user

    # Validate terms acceptance and required fields
    cond do
      not terms_accepted ->
        {:noreply,
         socket
         |> put_flash(:error, "You must accept the Terms and Conditions to continue.")
         |> assign(:terms_accepted, false)}

      String.trim(user_params["name"] || "") == "" ->
        {:noreply,
         socket
         |> put_flash(:error, "Name is required.")
         |> assign(:terms_accepted, terms_accepted)}

      true ->
        # Process the account setup
        process_account_setup(
          socket,
          user,
          user_params,
          delivery_params,
          invoice_params,
          same_as_delivery,
          marketing_opt_in
        )
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

  # Process complete account setup with user name, addresses, and optional password
  defp process_account_setup(
         socket,
         user,
         user_params,
         delivery_params,
         invoice_params,
         same_as_delivery,
         _marketing_opt_in
       ) do
    # Start with user profile update (name is always required)
    profile_update_result =
      user
      |> Accounts.User.update_profile_changeset(%{name: String.trim(user_params["name"])})
      |> Eatfair.Repo.update()

    case profile_update_result do
      {:ok, updated_user} ->
        # Update password if provided
        password_result =
          if String.trim(user_params["password"] || "") != "" do
            Accounts.update_user_password(updated_user, user_params)
          else
            {:ok, {updated_user, []}}
          end

        case password_result do
          {:ok, {final_user, _tokens}} ->
            # Create addresses
            address_result =
              Accounts.upsert_user_addresses(
                final_user,
                delivery_params,
                invoice_params,
                same_as_delivery
              )

            case address_result do
              {:ok, {_delivery_addr, _invoice_addr}} ->
                # TODO: Store marketing opt-in preference when persistence implemented

                redirect_path =
                  determine_redirect_path(final_user.id, socket.assigns.post_verify_order_id)

                {:noreply,
                 socket
                 |> put_flash(:info, "Account setup completed successfully!")
                 |> push_navigate(to: redirect_path)}

              {:error, reason} ->
                error_msg =
                  case reason do
                    {:delivery_error, _changeset} -> "Invalid delivery address information."
                    {:invoice_error, _changeset} -> "Invalid invoice address information."
                    _ -> "Could not save address information."
                  end

                {:noreply,
                 socket
                 |> put_flash(:error, error_msg)
                 |> assign(:terms_accepted, true)}
            end

          {:error, changeset} ->
            {:noreply,
             socket
             |> assign(:form, to_form(changeset))
             |> assign(:terms_accepted, true)
             |> put_flash(:error, "Password requirements not met.")}
        end

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:terms_accepted, true)
         |> put_flash(:error, "Please provide a valid name.")}
    end
  end

  # Get delivery address from the associated order
  defp get_addresses_from_order(post_verify_order_id) do
    case post_verify_order_id do
      nil ->
        # No order context, return empty address forms
        {%{}, %{}}

      order_id ->
        try do
          order = Orders.get_order!(order_id)
          # Parse the delivery address from order
          {street, city, postal_code} = parse_order_delivery_address(order.delivery_address)

          delivery_address = %{
            street_address: street,
            city: city,
            postal_code: postal_code,
            country: "Netherlands"
          }

          # Invoice address defaults to same as delivery
          invoice_address = delivery_address

          {delivery_address, invoice_address}
        rescue
          _ ->
            # If order not found, return empty forms
            {%{}, %{}}
        end
    end
  end

  # Use the new AddressParser utility for smart address parsing
  defp parse_order_delivery_address(delivery_address) when is_binary(delivery_address) do
    Eatfair.AddressParser.parse_delivery_address(delivery_address)
  end

  defp parse_order_delivery_address(_), do: {"", "", ""}
end
