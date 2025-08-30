defmodule Eatfair.Notifications.DonationAwareTest do
  use Eatfair.DataCase

  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  alias Eatfair.{Orders, Notifications}
  alias Eatfair.OrderTestSupport

  describe "donation-aware delivery notifications" do
    setup do
      customer = user_fixture()
      restaurant = restaurant_fixture()
      %{customer: customer, restaurant: restaurant}
    end

    test "delivered order with donation sends thank-you message with social sharing", %{
      customer: customer, 
      restaurant: restaurant
    } do
      # 📦 Create order with donation that gets delivered
      {:ok, order} = Orders.create_order_with_items(
        %{
          customer_id: customer.id,
          restaurant_id: restaurant.id,
          total_price: Decimal.new("25.00"),
          donation_amount: Decimal.new("3.50"),  # Customer donated!
          donation_currency: "EUR",
          delivery_address: "Thank You Street 123",
          status: "confirmed"
        },
        [%{meal_id: test_meal_fixture().id, quantity: 1}]
      )

      # 🚚 Update to delivered status through valid progression
      {:ok, _delivered_order} = OrderTestSupport.transition_to_delivered(order)

      # ✅ Should trigger thank-you notification
      events = Notifications.list_events_for_user(customer.id)
      delivered_events = Enum.filter(events, &(&1.data["new_status"] == "delivered"))
      
      assert length(delivered_events) == 1
      [event] = delivered_events

      # Should contain thank-you messaging and social sharing
      assert event.data["message_type"] == "thank_you"
      assert event.data["donation_amount"] == "3.50"
      assert event.data["social_share_url"] != nil
      assert event.data["social_message"] != nil
      
      # Should emphasize other ways to support
      assert event.data["support_options"] != nil
      assert is_list(event.data["support_options"])
      assert "social_sharing" in event.data["support_options"]
      assert "write_reviews" in event.data["support_options"]
    end

    test "delivered order without donation sends support request with donation options", %{
      customer: customer,
      restaurant: restaurant  
    } do
      # 📦 Create order without donation
      {:ok, order} = Orders.create_order_with_items(
        %{
          customer_id: customer.id,
          restaurant_id: restaurant.id,
          total_price: Decimal.new("18.75"),
          donation_amount: Decimal.new("0.00"),  # No donation
          delivery_address: "Support Request Ave 456",
          status: "confirmed"
        },
        [%{meal_id: test_meal_fixture().id, quantity: 2}]
      )

      # 🚚 Update to delivered status through valid progression
      {:ok, _delivered_order} = OrderTestSupport.transition_to_delivered(order)

      # ✅ Should trigger support request notification
      events = Notifications.list_events_for_user(customer.id)
      delivered_events = Enum.filter(events, &(&1.data["new_status"] == "delivered"))
      
      assert length(delivered_events) == 1
      [event] = delivered_events

      # Should contain support request messaging
      assert event.data["message_type"] == "support_request"  
      assert event.data["donation_amount"] == "0.00"
      refute Map.has_key?(event.data, "social_share_url")
      
      # Should include donation options and alternative support
      assert event.data["donation_url"] != nil
      assert event.data["donation_amounts"] != nil
      assert is_list(event.data["donation_amounts"])
      
      # Should include other ways to support
      assert event.data["support_options"] != nil
      assert "social_sharing" in event.data["support_options"] 
      assert "write_reviews" in event.data["support_options"]
      assert "recommend_platform" in event.data["support_options"]
    end

    test "donation messaging is encouraging and non-pushy", %{
      customer: customer,
      restaurant: restaurant
    } do
      # Test that messaging tone is appropriate for both scenarios
      
      # Case 1: With donation - should be grateful, not demanding
      {:ok, order_with_donation} = Orders.create_order_with_items(
        %{
          customer_id: customer.id,
          restaurant_id: restaurant.id,
          total_price: Decimal.new("30.00"),
          donation_amount: Decimal.new("2.00"),
          delivery_address: "Grateful Customer St",
          status: "confirmed"
        },
        [%{meal_id: test_meal_fixture().id, quantity: 1}]
      )
      
      # Transition to delivered status
      {:ok, _delivered_order_with_donation} = OrderTestSupport.transition_to_delivered(order_with_donation)

      # Case 2: Without donation - should be kind, not guilt-tripping  
      customer_2 = user_fixture()
      {:ok, order_without_donation} = Orders.create_order_with_items(
        %{
          customer_id: customer_2.id,
          restaurant_id: restaurant.id,
          total_price: Decimal.new("22.50"),
          donation_amount: Decimal.new("0.00"),
          delivery_address: "Kind Request Blvd",
          status: "confirmed"
        },
        [%{meal_id: test_meal_fixture().id, quantity: 1}]
      )
      
      # Transition to delivered status
      {:ok, _delivered_order_without_donation} = OrderTestSupport.transition_to_delivered(order_without_donation)

      # Check message tone for donated customer
      donor_events = Notifications.list_events_for_user(customer.id)
      donor_event = Enum.find(donor_events, &(&1.data["new_status"] == "delivered"))
      
      # Should be grateful, not demanding more
      assert donor_event.data["message_tone"] == "grateful"
      refute String.contains?(donor_event.data["message"] || "", "more")
      refute String.contains?(donor_event.data["message"] || "", "additional")

      # Check message tone for non-donor
      non_donor_events = Notifications.list_events_for_user(customer_2.id)  
      non_donor_event = Enum.find(non_donor_events, &(&1.data["new_status"] == "delivered"))
      
      # Should be kind request, not guilt-tripping
      assert non_donor_event.data["message_tone"] == "kind_request"
      refute String.contains?(non_donor_event.data["message"] || "", "should have")
      refute String.contains?(non_donor_event.data["message"] || "", "disappointed")
    end

    test "notifications include correct priority levels for delivered status", %{
      customer: customer,
      restaurant: restaurant
    } do
      # Both donation and non-donation delivery notifications should be normal priority
      {:ok, order} = Orders.create_order_with_items(
        %{
          customer_id: customer.id,
          restaurant_id: restaurant.id,
          total_price: Decimal.new("20.00"), 
          donation_amount: Decimal.new("1.50"),
          delivery_address: "Priority Test Road",
          status: "confirmed"
        },
        [%{meal_id: test_meal_fixture().id, quantity: 1}]
      )
      
      # Transition to delivered status
      {:ok, _delivered_order} = OrderTestSupport.transition_to_delivered(order)

      events = Notifications.list_events_for_user(customer.id)
      delivered_event = Enum.find(events, &(&1.data["new_status"] == "delivered"))
      
      # Delivery notifications should remain normal priority regardless of donation
      assert delivered_event.priority == "normal"
    end
  end

  # Helper function for test meals
  defp test_meal_fixture do
    restaurant = restaurant_fixture()
    Eatfair.RestaurantsFixtures.meal_fixture(%{restaurant_id: restaurant.id})
  end
end
