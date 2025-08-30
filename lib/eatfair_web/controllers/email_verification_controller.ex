defmodule EatfairWeb.EmailVerificationController do
  use EatfairWeb, :controller

  alias Eatfair.Accounts
  alias Eatfair.Orders

  def verify(conn, %{"token" => token}) do
    case Accounts.verify_email(token) do
      {:ok, verification} ->
        # If verification has an associated order, redirect to order tracking
        if verification.order_id do
          try do
            order = Orders.get_order!(verification.order_id)

            conn
            |> put_flash(:info, "Email verified! You can now track your order.")
            |> redirect(to: ~p"/orders/track/#{order.tracking_token}")
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
end
