defmodule EatfairWeb.UserLive.AccountSetup do
  use EatfairWeb, :live_view

  alias Eatfair.Accounts

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Only show account setup for users without passwords
    if user.hashed_password do
      # User already has password, redirect to settings
      socket =
        socket
        |> put_flash(:info, "Your account is already set up.")
        |> push_navigate(to: ~p"/users/settings")

      {:ok, socket}
    else
      changeset = Accounts.change_user_password(user, %{}, hash_password: false)

      {:ok,
       socket
       |> assign(:page_title, "Complete Account Setup")
       |> assign(:form, to_form(changeset))
       |> assign(:marketing_opt_in, false)
       |> assign(:terms_accepted, false)
       |> assign(:trigger_submit, false)}
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

    # Validate terms acceptance
    if not terms_accepted do
      {:noreply,
       socket
       |> put_flash(:error, "You must accept the Terms and Conditions to continue.")
       |> assign(:terms_accepted, false)}
    else
      case Accounts.update_user_password(socket.assigns.current_scope.user, user_params) do
        {:ok, {_user, _tokens}} ->
          # TODO: Store marketing opt-in preference

          {:noreply,
           socket
           |> put_flash(:info, "Account setup completed successfully!")
           |> push_navigate(to: ~p"/users/settings")}

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
    {:noreply,
     socket
     |> put_flash(:info, "You can set up your password later in settings.")
     |> push_navigate(to: ~p"/")}
  end
end
