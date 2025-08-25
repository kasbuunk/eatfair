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
      join: menu in Menu, on: meal.menu_id == menu.id,
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
  Calculates estimated delivery time for a restaurant to a given address.
  Uses simple distance-based calculation for MVP.
  """
  def estimate_delivery_time(%Restaurant{} = restaurant, _delivery_address) do
    # For MVP: Use average values since we don't have real distance calculation yet
    # Future: Integrate with mapping service for actual distance
    avg_distance_km = restaurant.delivery_radius_km / 2  # Assume average delivery is half the radius
    prep_time = restaurant.avg_preparation_time || 30
    delivery_time = round(avg_distance_km * restaurant.delivery_time_per_km)
    buffer_time = 5  # Safety buffer
    
    prep_time + delivery_time + buffer_time
  end
end
