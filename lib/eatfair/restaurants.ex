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
end
