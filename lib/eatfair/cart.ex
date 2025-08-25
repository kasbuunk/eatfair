defmodule Eatfair.Cart do
  @moduledoc """
  The Cart context for managing cart operations.
  """

  # alias Eatfair.Restaurants

  @doc """
  Represents a cart item structure.
  """
  defstruct [:meal_id, :quantity, :meal]

  @doc """
  Creates cart items from a cart map and restaurant.
  """
  def create_cart_items(cart, restaurant) do
    cart
    |> Enum.map(fn {meal_id, quantity} ->
      meal = find_meal(restaurant, meal_id)
      %__MODULE__{meal_id: meal_id, quantity: quantity, meal: meal}
    end)
    |> Enum.filter(fn item -> item.meal != nil end)
  end

  @doc """
  Calculates the total price of cart items.
  """
  def calculate_total(cart_items) do
    Enum.reduce(cart_items, Decimal.new(0), fn item, acc ->
      item_total = Decimal.mult(item.meal.price, item.quantity)
      Decimal.add(acc, item_total)
    end)
  end

  @doc """
  Gets the total item count in the cart.
  """
  def total_items(cart) when is_map(cart) do
    cart |> Map.values() |> Enum.sum()
  end

  def total_items(cart_items) when is_list(cart_items) do
    Enum.reduce(cart_items, 0, fn item, acc -> acc + item.quantity end)
  end

  @doc """
  Validates cart against minimum order requirements.
  """
  def validate_minimum_order(cart_total, restaurant) do
    case restaurant.min_order_value do
      nil ->
        {:ok, cart_total}

      min_value ->
        case Decimal.compare(cart_total, min_value) do
          :lt -> {:error, :minimum_not_met, min_value}
          _ -> {:ok, cart_total}
        end
    end
  end

  defp find_meal(restaurant, meal_id) do
    restaurant.menus
    |> Enum.flat_map(& &1.meals)
    |> Enum.find(&(&1.id == meal_id))
  end
end
