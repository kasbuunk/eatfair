defmodule EatfairWeb.RestaurantLive.Show do
  use EatfairWeb, :live_view

  alias Eatfair.Restaurants
  alias Eatfair.Reviews
  alias Eatfair.Reviews.Review
  alias Phoenix.LiveView

  @impl true
  # Guard against special or invalid IDs like "discover" by redirecting
  def mount(%{"id" => id}, _session, socket) when is_binary(id) do
    case Integer.parse(id) do
      {_, ""} ->
        # Valid integer ID (as string) – proceed with normal mount flow
        do_mount_show(id, socket)

      _ ->
        {:ok, LiveView.redirect(socket, to: ~p"/restaurants")}
    end
  end

  # Fallback for unexpected params
  def mount(_params, _session, socket) do
    {:ok, LiveView.redirect(socket, to: ~p"/restaurants")}
  end

  defp do_mount_show(id, socket) do
    restaurant = Restaurants.get_restaurant!(id)
    reviews = Reviews.list_reviews_for_restaurant(id)
    average_rating = Reviews.get_average_rating(id)
    review_count = Reviews.get_review_count(id)

    # Check if current user can review this restaurant (has delivered orders and hasn't reviewed yet)
    user_can_review =
      case socket.assigns.current_scope do
        %{user: user} -> Reviews.user_can_review?(user.id, id)
        _ -> false
      end

    # Also check if they have any orders (for messaging purposes)
    user_has_orders =
      case socket.assigns.current_scope do
        %{user: user} -> user_has_any_orders?(user.id, id)
        _ -> false
      end

    socket =
      socket
      |> assign(:restaurant, restaurant)
      |> assign(:cart, %{})
      |> assign(:cart_total, Decimal.new(0))
      |> assign(:reviews, reviews)
      |> assign(:average_rating, average_rating)
      |> assign(:review_count, review_count)
      |> assign(:user_can_review, user_can_review)
      |> assign(:user_has_orders, user_has_orders)
      |> assign(:location, nil)
      # Will be updated in handle_params based on location
      |> assign(:delivery_available, false)
      |> assign(:review_form, to_form(Reviews.change_review(%Review{})))
      |> assign(:show_review_form, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_location(socket, params["location"])
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, socket.assigns.restaurant.name)
  end

  defp apply_location(socket, nil) do
    # No location parameter - fall back to user's address if logged in
    delivery_available =
      case socket.assigns.current_scope do
        %{user: user} ->
          Restaurants.can_deliver_to_location?(socket.assigns.restaurant.id, user.id)

        _ ->
          false
      end

    socket
    |> assign(:location, nil)
    |> assign(:delivery_available, delivery_available)
  end

  defp apply_location(socket, location) when is_binary(location) do
    # Check delivery availability for the searched location
    delivery_available =
      case {socket.assigns.current_scope, Eatfair.GeoUtils.geocode_address(location)} do
        {%{user: _user}, {:ok, %{latitude: lat, longitude: lon}}} ->
          Eatfair.GeoUtils.within_delivery_range?(
            socket.assigns.restaurant.latitude,
            socket.assigns.restaurant.longitude,
            Decimal.new(Float.to_string(lat)),
            Decimal.new(Float.to_string(lon)),
            socket.assigns.restaurant.delivery_radius_km
          )

        _ ->
          false
      end

    socket
    |> assign(:location, location)
    |> assign(:delivery_available, delivery_available)
  end

  @impl true
  def handle_event("add_to_cart", %{"meal_id" => meal_id}, socket) do
    meal_id = String.to_integer(meal_id)
    meal = find_meal(socket.assigns.restaurant, meal_id)

    if meal do
      cart = socket.assigns.cart
      current_quantity = Map.get(cart, meal_id, 0)
      updated_cart = Map.put(cart, meal_id, current_quantity + 1)

      cart_total = calculate_cart_total(updated_cart, socket.assigns.restaurant)

      socket =
        socket
        |> assign(:cart, updated_cart)
        |> assign(:cart_total, cart_total)
        |> put_flash(:info, "Added #{meal.name} to cart")

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Meal not found")}
    end
  end

  def handle_event("remove_from_cart", %{"meal_id" => meal_id}, socket) do
    meal_id = String.to_integer(meal_id)
    cart = socket.assigns.cart

    updated_cart =
      case Map.get(cart, meal_id, 0) do
        quantity when quantity > 1 -> Map.put(cart, meal_id, quantity - 1)
        _ -> Map.delete(cart, meal_id)
      end

    cart_total = calculate_cart_total(updated_cart, socket.assigns.restaurant)

    socket =
      socket
      |> assign(:cart, updated_cart)
      |> assign(:cart_total, cart_total)

    {:noreply, socket}
  end

  def handle_event("checkout", _params, socket) do
    case socket.assigns.current_scope do
      %{user: nil} ->
        # Redirect to login with return URL
        {:noreply, push_navigate(socket, to: ~p"/users/log-in")}

      %{user: _user} ->
        # Navigate to checkout with cart data
        cart_encoded = encode_cart(socket.assigns.cart)
        restaurant_id = socket.assigns.restaurant.id

        checkout_url = ~p"/checkout/#{restaurant_id}?cart=#{cart_encoded}"
        {:noreply, push_navigate(socket, to: checkout_url)}
    end
  end

  def handle_event("toggle_review_form", _params, socket) do
    case socket.assigns.current_scope do
      %{user: nil} ->
        {:noreply, push_navigate(socket, to: ~p"/users/log-in")}

      _user ->
        {:noreply, assign(socket, :show_review_form, !socket.assigns.show_review_form)}
    end
  end

  def handle_event("submit_review", %{"review" => review_params}, socket) do
    case socket.assigns.current_scope do
      %{user: user} ->
        # Get a reviewable order for this user and restaurant
        case Reviews.get_reviewable_order(user.id, socket.assigns.restaurant.id) do
          nil ->
            {:noreply, put_flash(socket, :error, "You must complete an order before reviewing")}

          order ->
            attrs =
              Map.merge(review_params, %{
                "user_id" => user.id,
                "restaurant_id" => socket.assigns.restaurant.id,
                "order_id" => order.id
              })

            case Reviews.create_review(attrs) do
              {:ok, _review} ->
                # Refresh review data
                restaurant_id = socket.assigns.restaurant.id
                reviews = Reviews.list_reviews_for_restaurant(restaurant_id)
                average_rating = Reviews.get_average_rating(restaurant_id)
                review_count = Reviews.get_review_count(restaurant_id)

                socket =
                  socket
                  |> assign(:reviews, reviews)
                  |> assign(:average_rating, average_rating)
                  |> assign(:review_count, review_count)
                  # User can no longer review
                  |> assign(:user_can_review, false)
                  |> assign(:show_review_form, false)
                  |> assign(:review_form, to_form(Reviews.change_review(%Review{})))
                  |> put_flash(:info, "Review submitted successfully!")

                {:noreply, socket}

              {:error, changeset} ->
                {:noreply, assign(socket, :review_form, to_form(changeset))}
            end
        end

      _ ->
        {:noreply, push_navigate(socket, to: ~p"/users/log-in")}
    end
  end

  def handle_event("validate_review", %{"review" => review_params}, socket) do
    changeset = Reviews.change_review(%Review{}, review_params)
    {:noreply, assign(socket, :review_form, to_form(changeset))}
  end

  defp find_meal(restaurant, meal_id) do
    restaurant.menus
    |> Enum.flat_map(& &1.meals)
    |> Enum.find(&(&1.id == meal_id))
  end

  defp calculate_cart_total(cart, restaurant) do
    Enum.reduce(cart, Decimal.new(0), fn {meal_id, quantity}, acc ->
      meal = find_meal(restaurant, meal_id)

      if meal do
        item_total = Decimal.mult(meal.price, quantity)
        Decimal.add(acc, item_total)
      else
        acc
      end
    end)
  end

  # defp cart_item_count(cart) do
  #   cart |> Map.values() |> Enum.sum()
  # end

  defp encode_cart(cart) do
    cart
    |> Jason.encode!()
    |> URI.encode()
  end

  defp format_price(price) do
    "$#{Decimal.to_float(price) |> :erlang.float_to_binary(decimals: 2)}"
  end

  defp format_delivery_time(minutes) do
    "#{minutes} min"
  end

  defp user_has_any_orders?(user_id, restaurant_id) do
    import Ecto.Query
    alias Eatfair.Orders.Order

    from(o in Order,
      where: o.customer_id == ^user_id and o.restaurant_id == ^restaurant_id
    )
    |> Eatfair.Repo.exists?()
  end
end
