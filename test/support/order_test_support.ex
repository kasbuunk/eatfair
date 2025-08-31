defmodule Eatfair.OrderTestSupport do
  @moduledoc """
  Test support utilities for order management tests.

  This module provides helper functions to handle complex order status transitions
  in tests, ensuring tests follow valid business logic while remaining readable.
  """

  alias Eatfair.Orders

  @doc """
  Transitions an order from its current status to "delivered" through valid status progression.

  This function handles the complete order lifecycle:
  - confirmed → preparing → ready → out_for_delivery → delivered

  If the order is not in "confirmed" status, it will be moved to confirmed first.
  Returns the final delivered order.

  ## Examples

      iex> order = create_order(%{status: "confirmed"})
      iex> {:ok, delivered_order} = OrderTestSupport.transition_to_delivered(order)
      iex> delivered_order.status
      "delivered"
  """
  def transition_to_delivered(order) do
    # Ensure order starts at confirmed status
    {:ok, confirmed_order} =
      case order.status do
        "confirmed" -> {:ok, order}
        _ -> Orders.update_order_status(order, "confirmed")
      end

    # Follow valid status progression
    with {:ok, preparing_order} <- Orders.update_order_status(confirmed_order, "preparing"),
         {:ok, ready_order} <- Orders.update_order_status(preparing_order, "ready"),
         {:ok, out_for_delivery_order} <-
           Orders.update_order_status(ready_order, "out_for_delivery"),
         {:ok, delivered_order} <- Orders.update_order_status(out_for_delivery_order, "delivered") do
      {:ok, delivered_order}
    end
  end

  @doc """
  Transitions an order to "delivered" and returns just the order (not wrapped in tuple).

  Raises on error for use in tests where status transition failures should fail the test.

  ## Examples

      iex> order = create_order(%{status: "confirmed"})
      iex> delivered_order = OrderTestSupport.transition_to_delivered!(order)
      iex> delivered_order.status
      "delivered"
  """
  def transition_to_delivered!(order) do
    case transition_to_delivered(order) do
      {:ok, delivered_order} ->
        delivered_order

      {:error, changeset} ->
        raise "Failed to transition order to delivered: #{inspect(changeset.errors)}"
    end
  end

  @doc """
  Transitions an order through a specific sequence of statuses.

  ## Examples

      iex> order = create_order(%{status: "pending"})
      iex> {:ok, final_order} = OrderTestSupport.transition_through(order, ["confirmed", "preparing", "ready"])
      iex> final_order.status
      "ready"
  """
  def transition_through(order, statuses) when is_list(statuses) do
    Enum.reduce_while(statuses, {:ok, order}, fn status, {:ok, current_order} ->
      case Orders.update_order_status(current_order, status) do
        {:ok, updated_order} -> {:cont, {:ok, updated_order}}
        error -> {:halt, error}
      end
    end)
  end

  @doc """
  Creates donation-aware notification data based on order donation status.

  This helper generates the expected notification data structure for donation-aware
  delivery notifications, used for validating notification content in tests.
  """
  def expected_delivery_notification_data(order, message_type \\ nil) do
    donation_amount = order.donation_amount || Decimal.new("0.00")
    has_donation = Decimal.gt?(donation_amount, 0)

    base_data = %{
      "order_id" => order.id,
      "new_status" => "delivered",
      "restaurant_name" => order.restaurant.name,
      "donation_amount" => Decimal.to_string(donation_amount),
      "support_options" => ["social_sharing", "write_reviews"]
    }

    case message_type || if(has_donation, do: "thank_you", else: "support_request") do
      "thank_you" ->
        Map.merge(base_data, %{
          "message_type" => "thank_you",
          "message_tone" => "grateful",
          "social_share_url" => "https://example.com/share",
          "social_message" => "I just supported local food delivery!"
        })

      "support_request" ->
        Map.merge(base_data, %{
          "message_type" => "support_request",
          "message_tone" => "kind_request",
          "donation_url" => "https://example.com/donate",
          "donation_amounts" => ["1.00", "2.50", "5.00"],
          "support_options" => ["social_sharing", "write_reviews", "recommend_platform"]
        })
    end
  end
end
