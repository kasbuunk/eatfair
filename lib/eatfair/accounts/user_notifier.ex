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
        "#{base_url}/orders/#{order.id}/track?token=#{order.tracking_token}"
      end

    subject =
      if order do
        "Verify your email & track your EatFair order ##{order.id}"
      else
        "Verify your EatFair email address"
      end

    body =
      if order do
        build_order_verification_email_body(verification, order, verification_url, tracking_url, base_url)
      else
        build_simple_verification_email_body(verification, verification_url, base_url)
      end

    deliver(verification.email, subject, body)
  end

  defp build_order_verification_email_body(_verification, order, verification_url, tracking_url, base_url) do
    # Ensure order has all necessary associations loaded
    order = ensure_order_preloaded(order)
    
    assigns = %{
      order: order,
      restaurant: order.restaurant,
      verification_url: verification_url,
      tracking_url: tracking_url,
      terms_url: "#{base_url}/terms",
      privacy_url: "#{base_url}/privacy",
      base_url: base_url
    }
    
    template_path = Path.join([:code.priv_dir(:eatfair) || ".", "..", "lib", "eatfair_web", "templates", "email", "order_verification.text.eex"])
    
    # Fallback to relative path if priv_dir not available (during tests)
    template_path = 
      if File.exists?(template_path) do
        template_path
      else
        Path.join([File.cwd!(), "lib", "eatfair_web", "templates", "email", "order_verification.text.eex"])
      end
    
    EEx.eval_file(template_path, assigns: assigns)
  end

  defp build_simple_verification_email_body(_verification, verification_url, base_url) do
    assigns = %{
      verification_url: verification_url,
      terms_url: "#{base_url}/terms",
      privacy_url: "#{base_url}/privacy",
      base_url: base_url
    }
    
    template_path = Path.join([:code.priv_dir(:eatfair) || ".", "..", "lib", "eatfair_web", "templates", "email", "simple_verification.text.eex"])
    
    # Fallback to relative path if priv_dir not available (during tests)
    template_path = 
      if File.exists?(template_path) do
        template_path
      else
        Path.join([File.cwd!(), "lib", "eatfair_web", "templates", "email", "simple_verification.text.eex"])
      end
    
    EEx.eval_file(template_path, assigns: assigns)
  end
  # Helper to ensure order has necessary preloads for email template
  defp ensure_order_preloaded(order) do
    # Check if associations are already loaded
    if Ecto.assoc_loaded?(order.restaurant) && Ecto.assoc_loaded?(order.order_items) do
      # Check if order_items have meals loaded
      if Enum.any?(order.order_items, fn item -> not Ecto.assoc_loaded?(item.meal) end) do
        # Reload with proper associations
        Eatfair.Orders.get_order!(order.id)
      else
        order
      end
    else
      # Reload with proper associations
      Eatfair.Orders.get_order!(order.id)
    end
  end
end
