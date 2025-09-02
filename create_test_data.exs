# Test data generation script
# Run with: mix run create_test_data.exs

alias Eatfair.{Accounts, Restaurants, Orders}

# Ensure we have a restaurant owner
{:ok, restaurant_owner} = Accounts.register_user(%{
  email: "owner@testrestaurant.com",
  password: "password123",
  role: "restaurant_owner",
  confirmed_at: NaiveDateTime.utc_now()
})

# Create a restaurant
{:ok, restaurant} = Restaurants.create_restaurant(%{
  name: "Test Delivery Restaurant",
  address: "123 Main St, Amsterdam",
  owner_id: restaurant_owner.id,
  is_open: true,
  min_order_value: Decimal.new("15.00"),
  delivery_radius_km: 5
})

# Create a menu for the restaurant
{:ok, menu} = Restaurants.create_menu(%{
  name: "Main Menu",
  description: "Our main food selection",
  restaurant_id: restaurant.id,
  is_active: true
})

# Create some meals for the menu
meal_attrs = [
  %{name: "Margherita Pizza", price: Decimal.new("12.50"), description: "Classic pizza", menu_id: menu.id},
  %{name: "Chicken Burger", price: Decimal.new("8.75"), description: "Juicy chicken burger", menu_id: menu.id},
  %{name: "Caesar Salad", price: Decimal.new("7.25"), description: "Fresh Caesar salad", menu_id: menu.id}
]

meals = Enum.map(meal_attrs, fn attrs -> 
  {:ok, meal} = Restaurants.create_meal(attrs)
  meal
end)

# Create customers
customers = Enum.map(1..5, fn i -> 
  {:ok, customer} = Accounts.register_user(%{
    email: "customer#{i}@test.com",
    password: "password123",
    role: "customer",
    confirmed_at: NaiveDateTime.utc_now()
  })
  customer
end)

# Create couriers
couriers = Enum.map(1..3, fn i -> 
  {:ok, courier} = Accounts.register_user(%{
    email: "courier#{i}@test.com", 
    password: "password123",
    role: "courier",
    name: "Max Speedman #{i}",
    confirmed_at: NaiveDateTime.utc_now()
  })
  courier
end)

# Create some ready orders that can be staged
ready_orders = Enum.map(1..4, fn i ->
  customer = Enum.random(customers)
  meal = Enum.random(meals)
  
  {:ok, order} = Orders.create_order_with_items(
    %{
      customer_id: customer.id,
      restaurant_id: restaurant.id,
      total_price: meal.price,
      delivery_address: "#{100 + i} Test Street, Amsterdam",
      status: "ready",
      delivery_status: "not_ready"
    },
    [%{meal_id: meal.id, quantity: 1}]
  )
  
  order
end)

# Stage some of these orders
staged_orders = Enum.take(ready_orders, 3) |> Enum.map(fn order ->
  {:ok, staged} = Orders.stage_order(order)
  staged
end)

IO.puts("✅ Test data created successfully!")
IO.puts("🍕 Restaurant: #{restaurant.name} (ID: #{restaurant.id})")
IO.puts("👤 Owner: #{restaurant_owner.email}")
IO.puts("🍽️  Meals: #{length(meals)}")
IO.puts("👥 Customers: #{length(customers)}")
IO.puts("🚚 Couriers: #{length(couriers)}")
IO.puts("📦 Ready Orders: #{length(ready_orders)}")
IO.puts("⏰ Staged Orders: #{length(staged_orders)}")

IO.puts("\n🔑 Login credentials:")
IO.puts("Restaurant Owner: owner@testrestaurant.com / password123")
IO.puts("Courier 1: courier1@test.com / password123")
