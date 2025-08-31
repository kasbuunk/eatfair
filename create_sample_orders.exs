# Script to create sample orders for Night Owl restaurant across all stages
# This helps demonstrate the live dashboard functionality

require Logger
alias Eatfair.{Orders, Restaurants, Accounts, Repo}

# Find Night Owl restaurant and owner
night_owl_email = "owner@nightowl.nl"

case Accounts.get_user_by_email(night_owl_email) do
  nil ->
    IO.puts("❌ Night Owl owner not found with email: #{night_owl_email}")
    IO.puts("💡 Make sure to run: mix ecto.setup first")

  owner ->
    case Restaurants.get_user_restaurant(owner.id) do
      nil ->
        IO.puts("❌ Night Owl restaurant not found for owner")

      restaurant ->
        IO.puts("🦉 Found Night Owl Express NL (ID: #{restaurant.id})")
        
        # Get restaurant with menus and meals
        restaurant_with_meals = Restaurants.get_restaurant!(restaurant.id) |> Repo.preload(menus: :meals)
        
        all_meals = 
          restaurant_with_meals.menus
          |> Enum.flat_map(fn menu -> menu.meals end)
          |> Enum.filter(fn meal -> meal.is_available end)
        
        # Get some customers for orders
        import Ecto.Query
        customers = 
          from(u in Eatfair.Accounts.User, where: u.role == "customer", limit: 8)
          |> Repo.all()
        
        cond do
          length(customers) < 8 ->
            IO.puts("⚠️ Need at least 8 customers. Found: #{length(customers)}")
            IO.puts("💡 Run: mix ecto.setup to create test customers")
            
          length(all_meals) == 0 ->
            IO.puts("⚠️ Night Owl restaurant has no available meals")
            IO.puts("💡 Create some menus and meals for Night Owl first")
            
          true ->
          
          # Create orders across all statuses
          orders_to_create = [
            # 3 pending orders (needs urgent attention)
            %{status: "pending", customer: Enum.at(customers, 0), address: "Amstel 1, Amsterdam"},
            %{status: "pending", customer: Enum.at(customers, 1), address: "Prinsengracht 100, Amsterdam"},
            %{status: "pending", customer: Enum.at(customers, 2), address: "Dam Square 5, Amsterdam"},
            
            # 2 confirmed orders (accepted, waiting to prepare)
            %{status: "confirmed", customer: Enum.at(customers, 3), address: "Vondelpark 10, Amsterdam"},
            %{status: "confirmed", customer: Enum.at(customers, 4), address: "Museumplein 20, Amsterdam"},
            
            # 2 preparing orders (kitchen is working)
            %{status: "preparing", customer: Enum.at(customers, 5), address: "Jordaan 50, Amsterdam"},
            %{status: "preparing", customer: Enum.at(customers, 6), address: "Nieuwmarkt 3, Amsterdam"},
            
            # 1 ready order (ready for pickup/delivery)
            %{status: "ready", customer: Enum.at(customers, 7), address: "Leidseplein 15, Amsterdam"},
            
            # 1 out for delivery (on the way)
            %{status: "out_for_delivery", customer: Enum.at(customers, 0), address: "Rembrandtplein 8, Amsterdam"},
            
            # Some completed orders (for history)
            %{status: "delivered", customer: Enum.at(customers, 1), address: "Centraal Station 1, Amsterdam"},
            %{status: "delivered", customer: Enum.at(customers, 2), address: "Arena 10, Amsterdam"},
            
            # 1 cancelled order
            %{status: "cancelled", customer: Enum.at(customers, 3), address: "Bijlmer 25, Amsterdam"}
          ]
          
          IO.puts("📦 Creating #{length(orders_to_create)} sample orders...")
          
            Enum.with_index(orders_to_create, 1)
            |> Enum.each(fn {order_data, index} ->
              # Select 1-3 random meals
              selected_meals = all_meals |> Enum.take_random(min(Enum.random(1..3), length(all_meals)))
              
              # Calculate total price based on selected meals
              item_total = 
                selected_meals
                |> Enum.reduce(Decimal.new("0"), fn meal, acc ->
                  quantity = Enum.random(1..2) # 1-2 of each item
                  Decimal.add(acc, Decimal.mult(meal.price, quantity))
                end)
              
              # Ensure minimum order value is met
              total_price = 
                if Decimal.compare(item_total, restaurant.min_order_value || Decimal.new("12.00")) == :lt do
                  restaurant.min_order_value || Decimal.new("15.00")
                else
                  item_total
                end
              
              order_attrs = %{
                customer_id: order_data.customer.id,
                restaurant_id: restaurant.id,
                total_price: total_price,
                delivery_address: order_data.address,
                status: order_data.status
              }
              
              # Create order items
              items_attrs = 
                selected_meals
                |> Enum.map(fn meal ->
                  %{meal_id: meal.id, quantity: Enum.random(1..2)}
                end)
              
              case Orders.create_order_with_items(order_attrs, items_attrs) do
                {:ok, order} ->
                  IO.puts("✅ Created #{order_data.status} order ##{order.id} for #{order_data.customer.name} (€#{total_price})")
                  
                {:error, changeset} ->
                  IO.puts("❌ Failed to create #{order_data.status} order: #{inspect(changeset.errors)}")
              end
            end)
            
            IO.puts("🎉 Sample orders created for Night Owl Express NL!")
            IO.puts("🚀 Visit /restaurant/dashboard as owner@nightowl.nl to see live updates")
        end
    end
end
