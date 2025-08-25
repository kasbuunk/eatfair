defmodule Eatfair.Restaurants do
  @moduledoc """
  The Restaurants context.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Restaurants.Cuisine
  alias Eatfair.Restaurants.Menu
  alias Eatfair.Restaurants.Meal

  @doc """
  Returns the list of restaurants.

  ## Examples

      iex> list_restaurants()
      [%Restaurant{}, ...]

  """
  def list_restaurants do
    Restaurant
    |> preload([:cuisines, :menus])
    |> Repo.all()
  end

  @doc """
  Returns the list of open restaurants.
  """
  def list_open_restaurants do
    Restaurant
    |> where([r], r.is_open == true)
    |> preload([:cuisines, :menus])
    |> Repo.all()
  end

  @doc """
  Gets a single restaurant.

  Raises `Ecto.NoResultsError` if the Restaurant does not exist.

  ## Examples

      iex> get_restaurant!(123)
      %Restaurant{}

      iex> get_restaurant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_restaurant!(id) do
    Restaurant
    |> preload([:cuisines, menus: :meals])
    |> Repo.get!(id)
  end

  @doc """
  Creates a restaurant.

  ## Examples

      iex> create_restaurant(%{field: value})
      {:ok, %Restaurant{}}

      iex> create_restaurant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_restaurant(attrs \\ %{}) do
    %Restaurant{}
    |> Restaurant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a restaurant.

  ## Examples

      iex> update_restaurant(restaurant, %{field: new_value})
      {:ok, %Restaurant{}}

      iex> update_restaurant(restaurant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_restaurant(%Restaurant{} = restaurant, attrs) do
    restaurant
    |> Restaurant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a restaurant.

  ## Examples

      iex> delete_restaurant(restaurant)
      {:ok, %Restaurant{}}

      iex> delete_restaurant(restaurant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_restaurant(%Restaurant{} = restaurant) do
    Repo.delete(restaurant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking restaurant changes.

  ## Examples

      iex> change_restaurant(restaurant)
      %Ecto.Changeset{data: %Restaurant{}}

  """
  def change_restaurant(%Restaurant{} = restaurant, attrs \\ %{}) do
    Restaurant.changeset(restaurant, attrs)
  end

  @doc """
  Returns the list of restaurants with location data for discovery.
  """
  def list_restaurants_with_location_data do
    Restaurant
    |> where([r], r.is_open == true)
    |> preload([:cuisines, :menus])
    |> Repo.all()
  end

  @doc """
  Searches restaurants by name.
  """
  def search_restaurants(query) when is_binary(query) do
    search_query = "%#{String.downcase(query)}%"

    Restaurant
    |> where([r], r.is_open == true)
    |> where([r], like(fragment("lower(?)", r.name), ^search_query))
    |> preload([:cuisines, :menus])
    |> Repo.all()
  end

  @doc """
  Filters restaurants by various criteria.
  """
  def filter_restaurants(filters) when is_map(filters) do
    Restaurant
    |> where([r], r.is_open == true)
    |> apply_cuisine_filter(filters[:cuisine])
    |> apply_price_filter(filters[:max_price])
    |> apply_delivery_time_filter(filters[:max_delivery_time])
    |> preload([:cuisines, :menus])
    |> Repo.all()
  end

  @doc """
  Returns restaurants within delivery range of a user's location.
  Filters by the user's default address if available.
  """
  def list_restaurants_for_user(user_id) when is_integer(user_id) do
    case get_user_location(user_id) do
      nil ->
        # No address found, return all open restaurants
        list_open_restaurants()

      {lat, lon} ->
        # Filter restaurants by delivery range
        list_open_restaurants()
        |> Enum.filter(&within_delivery_range?(&1, lat, lon))
    end
  end

  @doc """
  Filters restaurants by location and other criteria.
  """
  def filter_restaurants_with_location(filters, user_id)
      when is_map(filters) and is_integer(user_id) do
    base_restaurants =
      case get_user_location(user_id) do
        nil ->
          # No location filtering, use regular filter
          filter_restaurants(filters)

        {lat, lon} ->
          # Apply location filtering first, then other filters
          filter_restaurants(filters)
          |> Enum.filter(&within_delivery_range?(&1, lat, lon))
      end

    base_restaurants
  end

  @doc """
  Searches restaurants by name with location filtering.
  """
  def search_restaurants_with_location(query, user_id)
      when is_binary(query) and is_integer(user_id) do
    base_restaurants = search_restaurants(query)

    case get_user_location(user_id) do
      nil ->
        base_restaurants

      {lat, lon} ->
        base_restaurants
        |> Enum.filter(&within_delivery_range?(&1, lat, lon))
    end
  end

  @doc """
  Checks if a restaurant can deliver to a specific location.
  """
  def can_deliver_to_location?(restaurant_id, user_id)
      when is_integer(restaurant_id) and is_integer(user_id) do
    restaurant = get_restaurant!(restaurant_id)

    case get_user_location(user_id) do
      # No location available
      nil -> false
      {lat, lon} -> within_delivery_range?(restaurant, lat, lon)
    end
  end

  defp get_user_location(user_id) do
    # Get user's default address coordinates
    case Eatfair.Accounts.list_user_addresses(user_id) do
      [] ->
        nil

      addresses ->
        default_address = Enum.find(addresses, & &1.is_default) || List.first(addresses)

        case default_address do
          %{latitude: lat, longitude: lon} when not is_nil(lat) and not is_nil(lon) ->
            {lat, lon}

          _ ->
            nil
        end
    end
  end

  defp within_delivery_range?(restaurant, customer_lat, customer_lon) do
    Eatfair.GeoUtils.within_delivery_range?(
      restaurant.latitude,
      restaurant.longitude,
      customer_lat,
      customer_lon,
      restaurant.delivery_radius_km
    )
  end

  defp apply_cuisine_filter(query, nil), do: query
  defp apply_cuisine_filter(query, ""), do: query

  defp apply_cuisine_filter(query, cuisine) do
    query
    |> join(:inner, [r], c in assoc(r, :cuisines))
    |> where([r, c], c.name == ^cuisine)
  end

  defp apply_price_filter(query, nil), do: query
  defp apply_price_filter(query, ""), do: query

  defp apply_price_filter(query, max_price) when is_binary(max_price) do
    {price_decimal, _} =
      Decimal.new(max_price) |> Decimal.to_float() |> Float.to_string() |> Float.parse()

    price_decimal = Decimal.from_float(price_decimal)
    where(query, [r], r.min_order_value <= ^price_decimal)
  end

  defp apply_delivery_time_filter(query, nil), do: query
  defp apply_delivery_time_filter(query, ""), do: query

  defp apply_delivery_time_filter(query, max_time) when is_binary(max_time) do
    {time_int, _} = Integer.parse(max_time)
    where(query, [r], r.avg_preparation_time <= ^time_int)
  end

  @doc """
  Returns the list of cuisines.
  """
  def list_cuisines do
    Repo.all(Cuisine)
  end

  @doc """
  Gets a single cuisine.
  """
  def get_cuisine!(id), do: Repo.get!(Cuisine, id)

  @doc """
  Creates a cuisine.
  """
  def create_cuisine(attrs \\ %{}) do
    %Cuisine{}
    |> Cuisine.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a restaurant's menus with meals.
  """
  def get_restaurant_menus(restaurant_id) do
    Menu
    |> where([m], m.restaurant_id == ^restaurant_id)
    |> preload(:meals)
    |> Repo.all()
  end

  @doc """
  Gets available meals for a restaurant.
  """
  def get_available_meals(restaurant_id) do
    from(meal in Meal,
      join: menu in Menu,
      on: meal.menu_id == menu.id,
      where: menu.restaurant_id == ^restaurant_id and meal.is_available == true,
      preload: [:menu]
    )
    |> Repo.all()
  end

  @doc """
  Creates a menu for a restaurant.
  """
  def create_menu(attrs \\ %{}) do
    %Menu{}
    |> Menu.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a menu.
  """
  def update_menu(%Menu{} = menu, attrs) do
    menu
    |> Menu.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a menu.
  """
  def delete_menu(%Menu{} = menu) do
    Repo.delete(menu)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking menu changes.
  """
  def change_menu(%Menu{} = menu, attrs \\ %{}) do
    Menu.changeset(menu, attrs)
  end

  @doc """
  Gets a single menu.
  """
  def get_menu!(id) do
    Menu
    |> preload(:meals)
    |> Repo.get!(id)
  end

  @doc """
  Creates a meal.
  """
  def create_meal(attrs \\ %{}) do
    %Meal{}
    |> Meal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meal.
  """
  def update_meal(%Meal{} = meal, attrs) do
    meal
    |> Meal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meal.
  """
  def delete_meal(%Meal{} = meal) do
    Repo.delete(meal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meal changes.
  """
  def change_meal(%Meal{} = meal, attrs \\ %{}) do
    Meal.changeset(meal, attrs)
  end

  @doc """
  Gets a single meal.
  """
  def get_meal!(id) do
    Repo.get!(Meal, id)
  end

  @doc """
  Checks if a user owns any restaurant.
  Used for authorization in restaurant management pages.
  """
  def user_owns_restaurant?(user_id) do
    Restaurant
    |> where([r], r.owner_id == ^user_id)
    |> Repo.exists?()
  end

  @doc """
  Gets the restaurant owned by a user.
  Returns nil if user doesn't own a restaurant.
  """
  def get_user_restaurant(user_id) do
    Restaurant
    |> where([r], r.owner_id == ^user_id)
    |> preload([:menus])
    |> Repo.one()
  end

  @doc """
  Gets a restaurant by owner ID.
  Alias for get_user_restaurant with consistent naming.
  """
  def get_restaurant_by_owner(owner_id) do
    get_user_restaurant(owner_id)
  end

  @doc """
  Calculates estimated delivery time for a restaurant to a given address.
  Uses simple distance-based calculation for MVP.
  """
  def estimate_delivery_time(%Restaurant{} = restaurant, _delivery_address) do
    # For MVP: Use average values since we don't have real distance calculation yet
    # Future: Integrate with mapping service for actual distance
    # Assume average delivery is half the radius
    avg_distance_km = restaurant.delivery_radius_km / 2
    prep_time = restaurant.avg_preparation_time || 30
    delivery_time = round(avg_distance_km * restaurant.delivery_time_per_km)
    # Safety buffer
    buffer_time = 5

    prep_time + delivery_time + buffer_time
  end
end
