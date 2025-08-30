defmodule Eatfair.OrdersEmailVerificationTest do
  use Eatfair.DataCase

  alias Eatfair.Orders
  alias Eatfair.Orders.Order
  alias Eatfair.Accounts

  describe "Order.generate_tracking_token/0" do
    test "generates a secure tracking token" do
      token = Order.generate_tracking_token()

      assert is_binary(token)
      # Should be reasonably long
      assert String.length(token) > 16
      assert Base.url_decode64(token, padding: false) |> elem(0) == :ok
    end

    test "generates unique tokens" do
      token1 = Order.generate_tracking_token()
      token2 = Order.generate_tracking_token()

      assert token1 != token2
    end
  end

  describe "Order.email_verified?/1" do
    test "returns true when email_status is verified" do
      order = %Order{email_status: "verified"}
      assert Order.email_verified?(order)
    end

    test "returns false when email_status is not verified" do
      order = %Order{email_status: "pending"}
      refute Order.email_verified?(order)

      order = %Order{email_status: "unverified"}
      refute Order.email_verified?(order)
    end
  end

  describe "Order.authenticated_order?/1" do
    test "returns true when customer_id is present" do
      order = %Order{customer_id: 123}
      assert Order.authenticated_order?(order)
    end

    test "returns false when customer_id is nil" do
      order = %Order{customer_id: nil}
      refute Order.authenticated_order?(order)
    end
  end

  describe "Order.primary_email/1" do
    test "returns customer_email for anonymous orders" do
      order = %Order{customer_id: nil, customer_email: "test@example.com"}
      assert Order.primary_email(order) == "test@example.com"
    end

    test "returns user email for authenticated orders" do
      user = %Eatfair.Accounts.User{email: "user@example.com"}
      order = %Order{customer_id: 123, customer: user}
      assert Order.primary_email(order) == "user@example.com"
    end

    test "returns nil when no email available" do
      order = %Order{customer_id: nil, customer_email: nil}
      assert Order.primary_email(order) == nil
    end
  end

  describe "create_order/1 with tracking token" do
    setup do
      user =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: user.id
        })

      %{restaurant: restaurant}
    end

    test "creates soft account and tracking token for anonymous orders", %{restaurant: restaurant} do
      # This should create a soft account (unconfirmed user) and associate the order with it
      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "test@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      assert order.tracking_token
      assert String.length(order.tracking_token) > 16
      # Should have a soft account user_id
      assert order.customer_id

      # Verify soft account was created
      soft_user = Accounts.get_user!(order.customer_id)
      assert soft_user.email == "test@example.com"
      # Should be unconfirmed initially
      refute soft_user.confirmed_at
    end

    test "does not generate tracking token for authenticated orders", %{restaurant: restaurant} do
      customer =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "user@example.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, order} =
        Orders.create_order(%{
          restaurant_id: restaurant.id,
          customer_id: customer.id,
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      assert order.customer_id == customer.id
      # Tracking token should not be generated for authenticated orders
      refute order.tracking_token
    end

    test "uses provided tracking token if specified", %{restaurant: restaurant} do
      custom_token = "custom-tracking-token-123"

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "test@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50"),
          tracking_token: custom_token
        })

      assert order.tracking_token == custom_token
    end
  end

  describe "update_order_email_status/2" do
    setup do
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "test@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      %{order: order}
    end

    test "updates email status to pending", %{order: order} do
      assert {:ok, updated_order} = Orders.update_order_email_status(order.id, "pending")

      assert updated_order.email_status == "pending"
      refute updated_order.email_verified_at
    end

    test "updates email status to verified and sets timestamp", %{order: order} do
      assert {:ok, updated_order} = Orders.update_order_email_status(order.id, "verified")

      assert updated_order.email_status == "verified"
      assert updated_order.email_verified_at
      assert DateTime.compare(updated_order.email_verified_at, DateTime.utc_now()) in [:lt, :eq]
    end

    test "rejects invalid email status", %{order: order} do
      # This should fail due to function guard
      assert_raise FunctionClauseError, fn ->
        Orders.update_order_email_status(order.id, "invalid_status")
      end
    end

    test "returns error for non-existent order" do
      assert_raise Ecto.NoResultsError, fn ->
        Orders.update_order_email_status(999_999, "verified")
      end
    end
  end

  describe "get_order_by_tracking_token/1" do
    setup do
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "test@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      %{order: order, restaurant: restaurant}
    end

    test "returns order for valid tracking token", %{order: order, restaurant: restaurant} do
      found_order = Orders.get_order_by_tracking_token(order.tracking_token)

      assert found_order.id == order.id
      assert found_order.customer_email == order.customer_email
      assert found_order.restaurant.id == restaurant.id
    end

    test "returns nil for invalid tracking token" do
      refute Orders.get_order_by_tracking_token("invalid-token")
    end

    test "returns nil for nil token" do
      refute Orders.get_order_by_tracking_token(nil)
    end
  end

  describe "list_orders_by_email/1" do
    setup do
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      email = "test@example.com"

      # Create multiple orders for same email
      {:ok, order1} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: email,
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      {:ok, order2} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: email,
          customer_phone: "+31 6 12345678",
          delivery_address: "Different Street 789, 1000 AB Amsterdam",
          total_price: Decimal.new("30.00")
        })

      # Create order for different email
      {:ok, _other_order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "other@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Other Street 123, 1000 AB Amsterdam",
          total_price: Decimal.new("15.75")
        })

      %{email: email, order1: order1, order2: order2}
    end

    test "returns orders for specified email", %{email: email, order1: order1, order2: order2} do
      orders = Orders.list_orders_by_email(email)

      assert length(orders) == 2
      order_ids = Enum.map(orders, & &1.id)
      assert order1.id in order_ids
      assert order2.id in order_ids

      # Verify that orders are sorted by insertion time (most recent first)
      # Note: Since both orders use the same soft account, they might have the same customer_id
      # but should still be properly ordered
      [first_order, second_order] = orders
      assert first_order.inserted_at >= second_order.inserted_at
    end

    test "returns empty list for non-existent email" do
      orders = Orders.list_orders_by_email("nonexistent@example.com")
      assert orders == []
    end
  end

  describe "associate_order_with_user/2" do
    setup do
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      user =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "user@example.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "soft-account@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      %{order: order, user: user}
    end

    test "associates anonymous order with user account", %{order: order, user: user} do
      # Verify order starts with soft account (unconfirmed user)
      # Should have soft account user_id
      assert order.customer_id
      refute order.account_created_from_order

      # Verify the soft account exists and is unconfirmed
      soft_user = Accounts.get_user!(order.customer_id)
      assert soft_user.email == "soft-account@example.com"
      refute soft_user.confirmed_at

      assert {:ok, updated_order} = Orders.associate_order_with_user(order.id, user.id)

      assert updated_order.customer_id == user.id
      assert updated_order.account_created_from_order
    end

    test "returns error for non-existent order" do
      user =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "test@example.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      assert_raise Ecto.NoResultsError, fn ->
        Orders.associate_order_with_user(999_999, user.id)
      end
    end
  end

  describe "email_has_orders?/1" do
    setup do
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      %{restaurant: restaurant}
    end

    test "returns true when email has orders", %{restaurant: restaurant} do
      email = "has-orders@example.com"

      {:ok, _order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: email,
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      assert Orders.email_has_orders?(email)
    end

    test "returns false when email has no orders" do
      refute Orders.email_has_orders?("no-orders@example.com")
    end
  end

  # Test PubSub broadcasting (integration test)
  describe "email verification broadcasting" do
    setup do
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "pubsub-test@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      %{order: order}
    end

    test "broadcasts email verification status change", %{order: order} do
      # Subscribe to email verification topic
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "email_verification:#{order.customer_email}")

      # Subscribe to order tracking topic
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "order_tracking:#{order.tracking_token}")

      # Update email status should trigger broadcast
      {:ok, _updated_order} = Orders.update_order_email_status(order.id, "verified")

      # Should receive broadcasts on both channels
      assert_receive {:email_verified, email}
      assert email == order.customer_email

      assert_receive {:email_verified, updated_order}
      assert updated_order.id == order.id
    end
  end
end
