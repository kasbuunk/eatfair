defmodule Eatfair.Accounts.UserNotifier do
  import Swoosh.Email

  alias Eatfair.Mailer
  alias Eatfair.Accounts.User
  alias Eatfair.Accounts.EmailVerification

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Eatfair", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver email verification instructions for anonymous orders.
  """
  def deliver_email_verification_instructions(%EmailVerification{} = verification, order \\ nil) do
    base_url = EatfairWeb.Endpoint.url()
    verification_url = "#{base_url}/verify-email/#{verification.token}"

    tracking_url =
      if order && order.tracking_token do
        "#{base_url}/orders/track/#{order.tracking_token}"
      end

    subject =
      if order do
        "Verify your email & track your EatFair order ##{order.id}"
      else
        "Verify your EatFair email address"
      end

    body =
      if order do
        build_order_verification_email_body(verification, order, verification_url, tracking_url)
      else
        build_simple_verification_email_body(verification, verification_url)
      end

    deliver(verification.email, subject, body)
  end

  defp build_order_verification_email_body(_verification, order, verification_url, tracking_url) do
    """

    ==============================

    Hi there!

    Thank you for your order from #{if Ecto.assoc_loaded?(order.restaurant), do: order.restaurant.name, else: "the restaurant"}!

    To track your order in real-time and receive delivery updates, please verify your email address:

    #{verification_url}

    #{if tracking_url, do: "Once verified, you can track your order here: #{tracking_url}"}

    Order Details:
    - Order ##{order.id}
    - Status: #{String.capitalize(order.status)}
    - Delivery to: #{order.delivery_address}

    Want to create an account for easier ordering?
    After verifying your email, you'll have the option to save your details for future orders.

    If you didn't place this order, please contact us immediately.

    ==============================
    """
  end

  defp build_simple_verification_email_body(_verification, verification_url) do
    """

    ==============================

    Hi there!

    Please verify your email address by clicking the link below:

    #{verification_url}

    This link will expire in 24 hours.

    If you didn't request this verification, please ignore this email.

    ==============================
    """
  end
end
