defmodule EatfairWeb.EmailVerificationController do
  use EatfairWeb, :controller

  alias Eatfair.Accounts
  alias Eatfair.Orders

  def verify(conn, %{"token" => token}) do
    case Accounts.verify_email(token) do
      # Auto-login flow for anonymous orders that create accounts
      {:ok, %{verification: verification, user: user}} ->
        if verification.order_id do
          # Log in the newly created user and redirect to account setup
          conn
          |> put_flash(:info, "Email verified! Complete your account setup below.")
          |> create_session_for_user(user)
          |> redirect(to: ~p"/users/account-setup")
        else
          # Regular user verification with auto-login
          conn
          |> put_flash(:info, "Email verified successfully!")
          |> create_session_for_user(user)
          |> redirect(to: ~p"/")
        end

      # Standard verification flow (no account creation)
      {:ok, verification} ->
        # If verification has an associated order, redirect to order tracking
        if verification.order_id do
          try do
            order = Orders.get_order!(verification.order_id)

            conn
            |> put_flash(:info, "Email verified! You can now track your order.")
            |> redirect(to: ~p"/orders/#{order.id}/track?token=#{order.tracking_token}")
          rescue
            Ecto.NoResultsError ->
              conn
              |> put_flash(:info, "Email verified successfully!")
              |> redirect(to: ~p"/")
          end
        else
          # Regular email verification, redirect to home with success message
          conn
          |> put_flash(:info, "Email verified successfully!")
          |> redirect(to: ~p"/")
        end

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Invalid verification link.")
        |> redirect(to: ~p"/")

      {:error, :expired} ->
        conn
        |> put_flash(:error, "Verification link has expired.")
        |> redirect(to: ~p"/")

      {:error, :already_verified} ->
        conn
        |> put_flash(:info, "This email has already been verified.")
        |> redirect(to: ~p"/")
    end
  end

  # Creates a session for the user without redirecting (unlike UserAuth.log_in_user/2)
  defp create_session_for_user(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, user_session_topic(token))
  end

  defp user_session_topic(token), do: "users_sessions:#{Base.url_encode64(token)}"
end
