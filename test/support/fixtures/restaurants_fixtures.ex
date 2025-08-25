defmodule Eatfair.RestaurantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Eatfair.Restaurants` context.
  """

  alias Eatfair.Restaurants
  alias Eatfair.AccountsFixtures

  def unique_restaurant_name, do: "Restaurant #{System.unique_integer()}"

  def valid_restaurant_attributes(attrs \\ %{}) do
    owner = attrs[:owner] || AccountsFixtures.confirmed_user_fixture(%{role: "restaurant_owner"})
    
    Enum.into(attrs, %{
      name: unique_restaurant_name(),
      address: "Test Street 123, Amsterdam",
      latitude: Decimal.new("52.3702"),
      longitude: Decimal.new("4.9002"),
      city: "Amsterdam",
      postal_code: "1012 AB",
      country: "Netherlands",
      avg_preparation_time: 30,
      delivery_radius_km: 5,
      min_order_value: Decimal.new("15.00"),
      rating: Decimal.new("4.5"),
      is_open: true,
      owner_id: owner.id
    })
  end

  def restaurant_fixture(attrs \\ %{}) do
    {:ok, restaurant} =
      attrs
      |> valid_restaurant_attributes()
      |> Restaurants.create_restaurant()

    restaurant
  end

  def cuisine_fixture(attrs \\ %{}) do
    {:ok, cuisine} =
      attrs
      |> Enum.into(%{name: "Test Cuisine #{System.unique_integer()}"})
      |> Restaurants.create_cuisine()

    cuisine
  end

  def menu_fixture(restaurant, attrs \\ %{}) do
    {:ok, menu} =
      attrs
      |> Enum.into(%{
        name: "Test Menu #{System.unique_integer()}",
        restaurant_id: restaurant.id
      })
      |> Restaurants.create_menu()

    menu
  end

  def meal_fixture(menu, attrs \\ %{}) do
    {:ok, meal} =
      attrs
      |> Enum.into(%{
        name: "Test Meal #{System.unique_integer()}",
        description: "A delicious test meal",
        price: Decimal.new("12.50"),
        menu_id: menu.id,
        is_available: true
      })
      |> Restaurants.create_meal()

    meal
  end

  @doc """
  Associates a restaurant with cuisines.
  """
  def associate_restaurant_cuisines(restaurant, cuisines) when is_list(cuisines) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    
    entries = Enum.map(cuisines, fn cuisine ->
      %{
        restaurant_id: restaurant.id,
        cuisine_id: cuisine.id,
        inserted_at: now,
        updated_at: now
      }
    end)
    
    Eatfair.Repo.insert_all("restaurant_cuisines", entries, on_conflict: :nothing)
    
    # Return the restaurant reloaded with cuisines
    Eatfair.Repo.preload(restaurant, :cuisines, force: true)
  end
  
  def associate_restaurant_cuisines(restaurant, cuisine) do
    associate_restaurant_cuisines(restaurant, [cuisine])
  end
end
