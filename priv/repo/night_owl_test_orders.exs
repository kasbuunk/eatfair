# Night Owl Express - Comprehensive Delivery Lifecycle Test Data
# Creates orders in ALL delivery stages for complete manual testing coverage
#
# Run after main seeds with: mix run priv/repo/night_owl_test_orders.exs
#
# Creates test data for:
# - Restaurant: Night Owl Express NL (24/7 Utrecht restaurant)
# - Customer: test@eatfair.nl 
# - Courier: courier.max@eatfair.nl (Max Speedman)
#
# Generates 29 total orders:
# - 9 core orders covering all status types (pending → delivery_failed)
# - 15 historical delivered orders (last 30 days)
# - 5 additional failed/cancelled orders for variety

import Ecto.Query
require Logger

alias Eatfair.Repo
alias Eatfair.Orders
alias Eatfair.Orders.{Order, OrderItem, Payment}
alias Eatfair.Restaurants
alias Eatfair.Accounts

IO.puts("🦉 Night Owl Express - Comprehensive Delivery Test Data Generator")
IO.puts("=" |> String.duplicate(70))

# ============================================================================
# 1. LOAD CORE ENTITIES
# ============================================================================

IO.puts("📋 Loading core entities...")

# Fetch Night Owl restaurant
restaurant = 
  case Restaurants.list_restaurants() |> Enum.find(&(&1.name == "Night Owl Express NL")) do
    nil ->
      IO.puts("❌ Night Owl Express NL restaurant not found!")
      IO.puts("💡 Run: mix run priv/repo/seeds.exs first")
      System.halt(1)
    r -> r
  end

IO.puts("✅ Found restaurant: #{restaurant.name} (ID: #{restaurant.id})")

# Fetch test customer
customer = 
  case Accounts.get_user_by_email("test@eatfair.nl") do
    nil ->
      IO.puts("❌ Test customer (test@eatfair.nl) not found!")
      IO.puts("💡 Run: mix run priv/repo/seeds.exs first")
      System.halt(1)
    c -> c
  end

IO.puts("✅ Found customer: #{customer.name} (#{customer.email})")

# Fetch Max courier
courier = 
  case Accounts.get_user_by_email("courier.max@eatfair.nl") do
    nil ->
      IO.puts("❌ Max courier (courier.max@eatfair.nl) not found!")
      IO.puts("💡 Run: mix run priv/repo/seeds.exs first")
      System.halt(1)
    c -> c
  end

IO.puts("✅ Found courier: #{courier.name} (#{courier.email})")

# ============================================================================
# 2. LOAD MENU ITEMS
# ============================================================================

IO.puts("🍕 Loading Night Owl menu items...")

restaurant_with_meals = 
  restaurant
  |> Repo.preload(menus: :meals)

all_meals = 
  restaurant_with_meals.menus
  |> Enum.flat_map(&(&1.meals))
  |> Enum.filter(&(&1.is_available))

if length(all_meals) == 0 do
  IO.puts("❌ Night Owl has no available meals!")
  IO.puts("💡 Check the seeds.exs file - Night Owl should have a comprehensive menu")
  System.halt(1)
end

IO.puts("✅ Found #{length(all_meals)} available meals")

# ============================================================================
# 3. HELPER FUNCTIONS
# ============================================================================

# Build proper timestamps for order status progression
build_timestamps = fn status, minutes_ago ->
  base_time = DateTime.utc_now() |> DateTime.add(-minutes_ago * 60, :second)
  base_naive = base_time |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
  
  case status do
    "pending" ->
      %{inserted_at: base_naive, updated_at: base_naive}
      
    "confirmed" ->
      confirmed_time = DateTime.add(base_time, -5 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: base_naive
      }
      
    "preparing" ->
      confirmed_time = DateTime.add(base_time, -15 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      preparing_time = DateTime.add(base_time, -5 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: confirmed_time,
        preparing_at: base_naive
      }
      
    "ready" ->
      confirmed_time = DateTime.add(base_time, -25 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      preparing_time = DateTime.add(base_time, -20 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      ready_time = DateTime.add(base_time, -5 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: confirmed_time,
        preparing_at: preparing_time,
        ready_at: base_naive,
        courier_id: courier.id,
        courier_assigned_at: ready_time
      }
      
    "out_for_delivery" ->
      confirmed_time = DateTime.add(base_time, -35 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      preparing_time = DateTime.add(base_time, -30 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      ready_time = DateTime.add(base_time, -15 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      out_time = DateTime.add(base_time, -5 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      assigned_time = DateTime.add(base_time, -10 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: confirmed_time,
        preparing_at: preparing_time,
        ready_at: ready_time,
        out_for_delivery_at: base_naive,
        courier_id: courier.id,
        courier_assigned_at: assigned_time,
        estimated_delivery_at: DateTime.add(base_time, 15 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      }
      
    "delivered" ->
      confirmed_time = DateTime.add(base_time, -60 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      preparing_time = DateTime.add(base_time, -55 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      ready_time = DateTime.add(base_time, -35 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      out_time = DateTime.add(base_time, -20 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      assigned_time = DateTime.add(base_time, -30 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: confirmed_time,
        preparing_at: preparing_time,
        ready_at: ready_time,
        out_for_delivery_at: out_time,
        delivered_at: base_naive,
        courier_id: courier.id,
        courier_assigned_at: assigned_time
      }
      
    "cancelled" ->
      # Could be cancelled from any stage - we'll assume from confirmed
      confirmed_time = DateTime.add(base_time, -15 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: confirmed_time,
        cancelled_at: base_naive
      }
      
    "rejected" ->
      # Rejected immediately after pending
      %{
        inserted_at: base_naive,
        updated_at: base_naive
      }
      
    "delivery_failed" ->
      # Failed during delivery attempt
      confirmed_time = DateTime.add(base_time, -90 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      preparing_time = DateTime.add(base_time, -85 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      ready_time = DateTime.add(base_time, -65 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      out_time = DateTime.add(base_time, -45 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      assigned_time = DateTime.add(base_time, -60 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
      %{
        inserted_at: confirmed_time,
        updated_at: base_naive,
        confirmed_at: confirmed_time,
        preparing_at: preparing_time,
        ready_at: ready_time,
        out_for_delivery_at: out_time,
        courier_id: courier.id,
        courier_assigned_at: assigned_time
      }
  end
end

# Create a complete order with items and payment
create_complete_order = fn order_attrs, order_spec ->
  # Select 1-3 random meals
  selected_meals = all_meals |> Enum.take_random(Enum.random(1..3))
  
  # Calculate total price
  item_total = 
    selected_meals
    |> Enum.reduce(Decimal.new("0"), fn meal, acc ->
      quantity = Enum.random(1..2)
      Decimal.add(acc, Decimal.mult(meal.price, quantity))
    end)
  
  # Ensure minimum order value
  total_price = 
    if Decimal.compare(item_total, restaurant.min_order_value || Decimal.new("12.00")) == :lt do
      Decimal.add(restaurant.min_order_value || Decimal.new("12.00"), Decimal.new("5.00"))
    else
      item_total
    end
  
  # Generate tracking token
  tracking_token = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  
  # Build complete order attributes
  complete_attrs = Map.merge(order_attrs, %{
    total_price: total_price,
    tracking_token: tracking_token,
    delivery_address: "Leidseplein 12, 1017 PT Amsterdam", # test customer's address
    phone_number: customer.phone_number || "+31-20-555-9999",
    delivery_notes: order_spec[:notes] || "Test order for manual testing"
  })
  
  # Insert order
  {:ok, order} = 
    %Order{}
    |> Order.changeset(complete_attrs)
    |> Repo.insert()
  
  # Insert order items
  selected_meals
  |> Enum.each(fn meal ->
    quantity = Enum.random(1..2)
    %OrderItem{}
    |> OrderItem.changeset(%{
      order_id: order.id,
      meal_id: meal.id,
      quantity: quantity,
      price: meal.price
    })
    |> Repo.insert!()
  end)
  
  # Insert payment
  payment_status = case order_spec[:status] do
    s when s in ["pending"] -> "pending"
    s when s in ["cancelled", "rejected"] -> "failed"
    s when s in ["delivered"] -> "completed"
    _ -> "processing"
  end
  
  %Payment{}
  |> Payment.changeset(%{
    order_id: order.id,
    amount: total_price,
    currency: "EUR",
    status: payment_status,
    payment_method: "card",
    provider: "stripe",
    provider_payment_id: "pi_test_#{System.unique_integer([:positive])}"
  })
  |> Repo.insert!()
  
  order
end

# ============================================================================
# 4. COMPREHENSIVE ORDER MATRIX - ALL STATUS TYPES
# ============================================================================

IO.puts("📦 Creating comprehensive order matrix...")

# Define all possible order statuses with realistic progression timing
order_matrix = [
  %{
    status: "pending", 
    delivery_status: "not_ready", 
    minutes_ago: 10,
    notes: "Payment processing - needs restaurant confirmation",
    is_delayed: false,
    donation_amount: Decimal.new("0.00")
  },
  %{
    status: "confirmed",
    delivery_status: "not_ready",
    minutes_ago: 25,
    notes: "Restaurant accepted - kitchen queue",
    is_delayed: false,
    donation_amount: Decimal.new("2.50")
  },
  %{
    status: "preparing",
    delivery_status: "not_ready", 
    minutes_ago: 40,
    notes: "Kitchen started cooking",
    is_delayed: true,
    delay_reason: "High demand - extra 10 minutes",
    donation_amount: Decimal.new("1.00")
  },
  %{
    status: "ready",
    delivery_status: "staged",
    minutes_ago: 55,
    notes: "Food ready - waiting for Max courier pickup",
    is_delayed: false,
    estimated_prep_time_minutes: 25,
    actual_prep_time_minutes: 35,
    donation_amount: Decimal.new("0.00")
  },
  %{
    status: "out_for_delivery",
    delivery_status: "in_transit", 
    minutes_ago: 70,
    notes: "Max is on the way - ETA 15 mins",
    is_delayed: false,
    donation_amount: Decimal.new("5.00")
  },
  %{
    status: "delivered",
    delivery_status: "delivered",
    minutes_ago: 120,
    notes: "Successfully delivered to customer",
    is_delayed: false,
    actual_prep_time_minutes: 30,
    donation_amount: Decimal.new("3.50")
  },
  %{
    status: "cancelled",
    delivery_status: "not_ready",
    minutes_ago: 90,
    notes: "Customer cancelled before preparation",
    is_delayed: false,
    donation_amount: Decimal.new("0.00")
  },
  %{
    status: "rejected", 
    delivery_status: "not_ready",
    minutes_ago: 5,
    notes: "Restaurant closed - automatic rejection",
    rejection_reason: "Restaurant temporarily closed",
    donation_amount: Decimal.new("0.00")
  },
  %{
    status: "delivery_failed",
    delivery_status: "scheduled", # Will be rescheduled
    minutes_ago: 150,
    notes: "Delivery failed - no one home, will retry tomorrow",
    is_delayed: true,
    delay_reason: "Customer not available for delivery",
    donation_amount: Decimal.new("1.50")
  }
]

IO.puts("🏗️ Creating #{length(order_matrix)} core orders (all statuses)...")

core_orders = 
  order_matrix
  |> Enum.with_index(1)
  |> Enum.map(fn {order_spec, index} ->
    timestamps = build_timestamps.(order_spec.status, order_spec.minutes_ago)
    
    # Build order attributes
    order_attrs = %{
      customer_id: customer.id,
      restaurant_id: restaurant.id,
      status: order_spec.status,
      delivery_status: order_spec.delivery_status,
      is_delayed: order_spec[:is_delayed] || false,
      delay_reason: order_spec[:delay_reason],
      rejection_reason: order_spec[:rejection_reason],
      special_instructions: "Test order ##{index} - #{order_spec.status} status",
      estimated_prep_time_minutes: order_spec[:estimated_prep_time_minutes],
      actual_prep_time_minutes: order_spec[:actual_prep_time_minutes],
      donation_amount: order_spec[:donation_amount] || Decimal.new("0.00"),
      donation_currency: "EUR"
    }
    |> Map.merge(timestamps)
    
    order = create_complete_order.(order_attrs, order_spec)
    
    IO.puts("✅ Created #{order_spec.status} order ##{order.id} (#{order_spec.minutes_ago} mins ago)")
    order
  end)

# ============================================================================
# 5. HISTORICAL DATA - DELIVERED ORDERS (LAST 30 DAYS)
# ============================================================================

IO.puts("📚 Creating historical delivered orders (last 30 days)...")

historical_orders = 
  1..15
  |> Enum.map(fn i ->
    # Random day in last 30 days
    days_ago = Enum.random(1..30)
    # Random hour (avoid night hours for realistic pattern)
    hour_offset = Enum.random(10..22)
    minute_offset = Enum.random(0..59)
    
    # Calculate exact time
    historical_time = 
      DateTime.utc_now()
      |> DateTime.add(-days_ago * 24 * 60 * 60, :second)
      |> DateTime.add(-hour_offset * 60 * 60, :second) 
      |> DateTime.add(-minute_offset * 60, :second)
    
    # Build delivered order with proper progression
    delivered_time = historical_time |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    out_time = DateTime.add(historical_time, -20 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    ready_time = DateTime.add(historical_time, -35 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    prep_time = DateTime.add(historical_time, -55 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    confirmed_time = DateTime.add(historical_time, -60 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    assigned_time = DateTime.add(historical_time, -30 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
    
    order_attrs = %{
      customer_id: customer.id,
      restaurant_id: restaurant.id,
      status: "delivered",
      delivery_status: "delivered",
      inserted_at: confirmed_time,
      updated_at: delivered_time,
      confirmed_at: confirmed_time,
      preparing_at: prep_time,
      ready_at: ready_time,
      out_for_delivery_at: out_time,
      delivered_at: delivered_time,
      courier_id: courier.id,
      courier_assigned_at: assigned_time,
      actual_prep_time_minutes: Enum.random(15..45),
      donation_amount: if(rem(i, 4) == 0, do: Decimal.new("#{Enum.random(1..5)}.50"), else: Decimal.new("0.00")),
      donation_currency: "EUR"
    }
    
    order_spec = %{
      status: "delivered",
      notes: "Historical order - delivered successfully #{days_ago} days ago"
    }
    
    order = create_complete_order.(order_attrs, order_spec)
    
    if rem(i, 5) == 0, do: IO.puts("✅ Created historical order ##{order.id} (#{days_ago} days ago)")
    order
  end)

# ============================================================================
# 6. ADDITIONAL FAILED/CANCELLED ORDERS FOR VARIETY
# ============================================================================

IO.puts("💥 Creating additional failed/cancelled orders...")

variety_statuses = ["cancelled", "delivery_failed", "rejected", "cancelled", "delivery_failed"]

variety_orders = 
  variety_statuses
  |> Enum.with_index(1)
  |> Enum.map(fn {status, i} ->
    days_ago = Enum.random(2..15)
    hour_offset = Enum.random(12..23)
    
    variety_time = 
      DateTime.utc_now()
      |> DateTime.add(-days_ago * 24 * 60 * 60, :second)
      |> DateTime.add(-hour_offset * 60 * 60, :second)
    
    timestamps = case status do
      "cancelled" ->
        base_time = variety_time |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        confirmed_time = DateTime.add(variety_time, -10 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        %{
          inserted_at: confirmed_time,
          updated_at: base_time,
          confirmed_at: confirmed_time,
          cancelled_at: base_time
        }
        
      "delivery_failed" ->
        base_time = variety_time |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        confirmed_time = DateTime.add(variety_time, -90 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        prep_time = DateTime.add(variety_time, -75 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        ready_time = DateTime.add(variety_time, -45 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        out_time = DateTime.add(variety_time, -25 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        assigned_time = DateTime.add(variety_time, -50 * 60, :second) |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        %{
          inserted_at: confirmed_time,
          updated_at: base_time,
          confirmed_at: confirmed_time,
          preparing_at: prep_time,
          ready_at: ready_time,
          out_for_delivery_at: out_time,
          courier_id: courier.id,
          courier_assigned_at: assigned_time
        }
        
      "rejected" ->
        base_time = variety_time |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        %{
          inserted_at: base_time,
          updated_at: base_time
        }
    end
    
    order_attrs = Map.merge(%{
      customer_id: customer.id,
      restaurant_id: restaurant.id,
      status: status,
      delivery_status: "not_ready",
      rejection_reason: if(status == "rejected", do: "High order volume - unable to fulfill", else: nil),
      delay_reason: if(status == "delivery_failed", do: "Address inaccessible", else: nil)
    }, timestamps)
    
    order_spec = %{
      status: status,
      notes: "Historical #{status} order for testing variety"
    }
    
    create_complete_order.(order_attrs, order_spec)
  end)

# ============================================================================
# 7. SUMMARY REPORT
# ============================================================================

all_orders = core_orders ++ historical_orders ++ variety_orders
total_count = length(all_orders)

# Count by status
status_counts = 
  all_orders
  |> Enum.group_by(&(&1.status))
  |> Map.new(fn {status, orders} -> {status, length(orders)} end)

IO.puts("")
IO.puts("🎉 NIGHT OWL TEST DATA GENERATION COMPLETE!")
IO.puts("=" |> String.duplicate(70))
IO.puts("📊 SUMMARY:")
IO.puts("   • Total orders created: #{total_count}")
IO.puts("   • Restaurant: #{restaurant.name}")  
IO.puts("   • Customer: #{customer.name} (#{customer.email})")
IO.puts("   • Courier: #{courier.name} (#{courier.email})")
IO.puts("")
IO.puts("📈 STATUS BREAKDOWN:")

status_counts
|> Enum.sort_by(fn {status, _count} -> 
  # Sort by typical order progression
  case status do
    "pending" -> 1
    "confirmed" -> 2  
    "preparing" -> 3
    "ready" -> 4
    "out_for_delivery" -> 5
    "delivered" -> 6
    "cancelled" -> 7
    "rejected" -> 8
    "delivery_failed" -> 9
  end
end)
|> Enum.each(fn {status, count} ->
  IO.puts("   • #{String.pad_trailing(status, 20)}: #{count} orders")
end)

IO.puts("")
IO.puts("🔗 MANUAL TESTING URLS:")
IO.puts("   • Customer Dashboard: http://localhost:4000/dashboard")
IO.puts("   • Restaurant Dashboard: http://localhost:4000/restaurant/dashboard") 
IO.puts("   • Order Tracking: http://localhost:4000/track")

# Show a few tracking tokens for immediate testing
sample_tracking_tokens = 
  core_orders
  |> Enum.take(3)
  |> Enum.map(&(&1.tracking_token))

IO.puts("")
IO.puts("🎯 SAMPLE TRACKING TOKENS:")
sample_tracking_tokens
|> Enum.with_index(1)
|> Enum.each(fn {token, i} ->
  IO.puts("   #{i}. http://localhost:4000/track/#{token}")
end)

IO.puts("")
IO.puts("🔑 LOGIN CREDENTIALS:")
IO.puts("   • Customer: test@eatfair.nl / password123456")
IO.puts("   • Restaurant Owner: owner@nightowl.nl / password123456")
IO.puts("   • Courier: courier.max@eatfair.nl / password123456")
IO.puts("")
IO.puts("✨ Ready for comprehensive manual testing across all delivery stages!")
