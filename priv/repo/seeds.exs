# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Eatfair.Repo.insert!(%Eatfair.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias Eatfair.Repo
alias Eatfair.Accounts
alias Eatfair.Accounts.User
alias Eatfair.Restaurants
alias Eatfair.Restaurants.{Restaurant, Cuisine, Menu, Meal}

# Clear existing data in development
if Mix.env() == :dev do
  # Delete in dependency order
  Repo.delete_all(Meal)
  Repo.delete_all(Menu)
  Repo.delete_all(from(r in "restaurant_cuisines"))
  
  # Delete addresses table if exists
  try do
    Repo.delete_all(from(a in "addresses"))
  rescue
    _ -> :ok
  end
  
  Repo.delete_all(Restaurant)
  Repo.delete_all(Cuisine)
  
  # Delete all users to avoid conflicts
  Repo.delete_all(User)
end

# Create cuisines
cuisines_data = [
  "Italian", "Chinese", "Mexican", "Indian", "Thai", 
  "Japanese", "Mediterranean", "American", "French", "Korean"
]

cuisines = 
  Enum.map(cuisines_data, fn name ->
    {:ok, cuisine} = Restaurants.create_cuisine(%{name: name})
    cuisine
  end)

IO.puts("Created #{length(cuisines)} cuisines")

# Create restaurant owners
restaurant_owners = [
  %{
    name: "Marco Rossi",
    email: "marco@bellaitalia.com",
    password: "password123456",
    role: "restaurant_owner",
    phone_number: "+31-20-555-0101",
  },
  %{
    name: "Wei Chen",
    email: "wei@goldenlotus.com", 
    password: "password123456",
    role: "restaurant_owner",
    phone_number: "+31-20-555-0102",
  },
  %{
    name: "Marie Dubois",
    email: "marie@jordaanbistro.com",
    password: "password123456", 
    role: "restaurant_owner",
    phone_number: "+31-20-555-0103",
  },
  %{
    name: "Raj Patel",
    email: "raj@spicegarden.com",
    password: "password123456",
    role: "restaurant_owner", 
    phone_number: "+31-30-555-0104",
  },
  %{
    name: "Carlos Mendoza",
    email: "carlos@utrechttaco.com",
    password: "password123456",
    role: "restaurant_owner", 
    phone_number: "+31-30-555-0105",
  }
]

owners = 
  Enum.map(restaurant_owners, fn attrs ->
    attrs = Map.put(attrs, :role, "restaurant_owner")
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert!()
    |> User.confirm_changeset()
    |> Repo.update!()
  end)

IO.puts("Created #{length(owners)} restaurant owners")

# Create restaurants with realistic Netherlands geographic data
# Distributed around Amsterdam, Utrecht, Het Gooi for testing location-based search
restaurants_data = [
  # Amsterdam restaurants
  %{
    name: "Bella Italia Amsterdam",
    address: "Nieuwmarkt 15, 1012 CR Amsterdam",
    latitude: Decimal.new("52.3702"),
    longitude: Decimal.new("4.9002"),
    city: "Amsterdam",
    postal_code: "1012 CR",
    country: "Netherlands",
    avg_preparation_time: 45,
    delivery_radius_km: 8,
    min_order_value: Decimal.new("15.00"),
    rating: Decimal.new("4.5"),
    image_url: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop&crop=center",
    owner_id: Enum.at(owners, 0).id,
    cuisine_names: ["Italian"]
  },
  %{
    name: "Golden Lotus",
    address: "Zeedijk 106, 1012 BB Amsterdam",
    latitude: Decimal.new("52.3744"),
    longitude: Decimal.new("4.9006"),
    city: "Amsterdam",
    postal_code: "1012 BB",
    country: "Netherlands",
    avg_preparation_time: 30,
    delivery_radius_km: 6,
    min_order_value: Decimal.new("20.00"),
    rating: Decimal.new("4.2"),
    image_url: "https://static.designmynight.com/uploads/2024/05/Gouqi-London-Chinese-Restaurant-Review.jpg",
    owner_id: Enum.at(owners, 1).id,
    cuisine_names: ["Chinese"]
  },
  %{
    name: "Jordaan Bistro",
    address: "Prinsengracht 287, 1016 GW Amsterdam",
    latitude: Decimal.new("52.3747"),
    longitude: Decimal.new("4.8841"),
    city: "Amsterdam",
    postal_code: "1016 GW",
    country: "Netherlands",
    avg_preparation_time: 35,
    delivery_radius_km: 7,
    min_order_value: Decimal.new("22.00"),
    rating: Decimal.new("4.6"),
    image_url: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop&crop=center",
    owner_id: Enum.at(owners, 2).id,
    cuisine_names: ["French"]
  },
  
  # Utrecht restaurants
  %{
    name: "Spice Garden Utrecht",
    address: "Oudegracht 158, 3511 AZ Utrecht",
    latitude: Decimal.new("52.0907"),
    longitude: Decimal.new("5.1214"),
    city: "Utrecht",
    postal_code: "3511 AZ",
    country: "Netherlands",
    avg_preparation_time: 40,
    delivery_radius_km: 10,
    min_order_value: Decimal.new("18.00"),
    rating: Decimal.new("4.3"),
    image_url: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop&crop=center",
    owner_id: Enum.at(owners, 3).id,
    cuisine_names: ["Indian"]
  },
  %{
    name: "Utrecht Taco Bar",
    address: "Nobelstraat 149, 3512 EM Utrecht",
    latitude: Decimal.new("52.0840"),
    longitude: Decimal.new("5.1293"),
    city: "Utrecht",
    postal_code: "3512 EM",
    country: "Netherlands",
    avg_preparation_time: 25,
    delivery_radius_km: 5,
    min_order_value: Decimal.new("12.00"),
    rating: Decimal.new("4.7"),
    image_url: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400&h=300&fit=crop&crop=center",
    owner_id: Enum.at(owners, 4).id,
    cuisine_names: ["Mexican"]
  }
]

restaurants =
  Enum.map(restaurants_data, fn %{cuisine_names: cuisine_names} = attrs ->
    attrs = Map.delete(attrs, :cuisine_names)
    
    {:ok, restaurant} = Restaurants.create_restaurant(attrs)
    
    # Associate with cuisines
    restaurant_cuisines = 
      Enum.map(cuisine_names, fn name ->
        cuisine = Enum.find(cuisines, fn c -> c.name == name end)
        %{restaurant_id: restaurant.id, cuisine_id: cuisine.id, inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()}
      end)
    
    Repo.insert_all("restaurant_cuisines", restaurant_cuisines)
    
    restaurant
  end)

IO.puts("Created #{length(restaurants)} restaurants")

# Create menus and meals for each restaurant
menus_and_meals = [
  # Bella Italia
  %{
    restaurant: Enum.at(restaurants, 0),
    menus: [
      %{
        name: "Main Dishes",
        meals: [
          %{name: "Spaghetti Carbonara", description: "Classic Roman pasta with eggs, pecorino cheese, and pancetta", price: Decimal.new("18.50")},
          %{name: "Margherita Pizza", description: "Traditional pizza with tomato, mozzarella, and fresh basil", price: Decimal.new("16.00")},
          %{name: "Osso Buco", description: "Braised veal shanks with vegetables in white wine", price: Decimal.new("28.00")},
          %{name: "Chicken Parmigiana", description: "Breaded chicken breast with marinara and mozzarella", price: Decimal.new("22.00")}
        ]
      },
      %{
        name: "Appetizers",
        meals: [
          %{name: "Bruschetta", description: "Grilled bread with tomatoes, garlic, and basil", price: Decimal.new("8.50")},
          %{name: "Antipasto Platter", description: "Selection of cured meats, cheeses, and olives", price: Decimal.new("14.00")}
        ]
      }
    ]
  },
  # Golden Lotus
  %{
    restaurant: Enum.at(restaurants, 1),
    menus: [
      %{
        name: "Main Dishes",
        meals: [
          %{name: "Kung Pao Chicken", description: "Diced chicken with peanuts and chili peppers", price: Decimal.new("15.50")},
          %{name: "Sweet and Sour Pork", description: "Battered pork with pineapple and bell peppers", price: Decimal.new("16.50")},
          %{name: "Beef and Broccoli", description: "Tender beef stir-fried with fresh broccoli", price: Decimal.new("17.00")},
          %{name: "Ma Po Tofu", description: "Silky tofu in spicy Sichuan sauce", price: Decimal.new("13.50")}
        ]
      },
      %{
        name: "Noodles & Rice",
        meals: [
          %{name: "Beef Lo Mein", description: "Soft noodles with beef and vegetables", price: Decimal.new("14.00")},
          %{name: "Yang Chow Fried Rice", description: "Fried rice with shrimp, char siu, and eggs", price: Decimal.new("12.50")}
        ]
      }
    ]
  },
  # Taco Fiesta  
  %{
    restaurant: Enum.at(restaurants, 2),
    menus: [
      %{
        name: "Tacos",
        meals: [
          %{name: "Carnitas Tacos", description: "Slow-cooked pork with onions and cilantro (3 pieces)", price: Decimal.new("9.50")},
          %{name: "Carne Asada Tacos", description: "Grilled steak with guacamole and salsa (3 pieces)", price: Decimal.new("11.00")},
          %{name: "Fish Tacos", description: "Battered fish with cabbage and chipotle mayo (3 pieces)", price: Decimal.new("12.50")},
          %{name: "Vegetarian Tacos", description: "Black beans, peppers, and avocado (3 pieces)", price: Decimal.new("8.50")}
        ]
      },
      %{
        name: "Mains",
        meals: [
          %{name: "Chicken Burrito", description: "Large flour tortilla with rice, beans, and chicken", price: Decimal.new("10.50")},
          %{name: "Beef Quesadilla", description: "Grilled tortilla with cheese and seasoned beef", price: Decimal.new("9.00")}
        ]
      }
    ]
  },
  # Spice Garden
  %{
    restaurant: Enum.at(restaurants, 3),
    menus: [
      %{
        name: "Curry Dishes",
        meals: [
          %{name: "Chicken Tikka Masala", description: "Tender chicken in creamy tomato curry", price: Decimal.new("17.50")},
          %{name: "Beef Vindaloo", description: "Spicy beef curry with potatoes", price: Decimal.new("19.00")},
          %{name: "Palak Paneer", description: "Cottage cheese in creamy spinach gravy", price: Decimal.new("15.50")},
          %{name: "Dal Makhani", description: "Rich black lentils cooked with butter and cream", price: Decimal.new("13.50")}
        ]
      },
      %{
        name: "Breads & Rice",
        meals: [
          %{name: "Basmati Rice", description: "Fragrant long-grain rice", price: Decimal.new("4.50")},
          %{name: "Garlic Naan", description: "Leavened bread with garlic and butter", price: Decimal.new("3.50")},
          %{name: "Chicken Biryani", description: "Aromatic rice with spiced chicken", price: Decimal.new("18.00")}
        ]
      }
    ]
  }
]

Enum.each(menus_and_meals, fn %{restaurant: restaurant, menus: menus_data} ->
  Enum.each(menus_data, fn %{name: menu_name, meals: meals_data} ->
    {:ok, menu} = Repo.insert(%Menu{
      name: menu_name,
      restaurant_id: restaurant.id
    })
    
    Enum.each(meals_data, fn meal_attrs ->
      Repo.insert!(%Meal{
        name: meal_attrs.name,
        description: meal_attrs.description,
        price: meal_attrs.price,
        menu_id: menu.id,
        is_available: true
      })
    end)
  end)
end)

IO.puts("Created menus and meals for all restaurants")

# Create sample customers with Netherlands addresses for geographic testing
customers_data = [
  %{
    name: "Piet van Amsterdam",
    email: "piet@example.nl",
    password: "password123456", 
    role: "customer",
    phone_number: "+31-20-555-1001",
    default_address: "Damrak 70, 1012 LM Amsterdam"  # Near Amsterdam restaurants
  },
  %{
    name: "Emma Janssen", 
    email: "emma@example.nl",
    password: "password123456",
    role: "customer", 
    phone_number: "+31-30-555-1002",
    default_address: "Lange Nieuwstraat 22, 3512 PH Utrecht"  # Near Utrecht restaurants
  },
  %{
    name: "Lisa de Vries",
    email: "lisa@example.nl", 
    password: "password123456",
    role: "customer",
    phone_number: "+31-35-555-1003",
    default_address: "Kerkstraat 15, 1251 RE Laren"  # Het Gooi area - should test distance filtering
  },
  %{
    name: "Test Customer",
    email: "test@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-9999",
    default_address: "Leidseplein 12, 1017 PT Amsterdam"  # Central Amsterdam for easy manual testing
  },
  # ============ ENHANCED SEED DATA - SPECIFIC USER ROLES ============
  # Consumer with extensive order history
  %{
    name: "Jan de Frequent",
    email: "frequent@example.nl",
    password: "password123456", 
    role: "customer",
    phone_number: "+31-20-555-1011",
    default_address: "Herengracht 123, 1015 BR Amsterdam"  # Amsterdam Canal District
  },
  # Consumer with dietary preferences
  %{
    name: "Sophie Vegano",
    email: "vegan@example.nl",
    password: "password123456", 
    role: "customer",
    phone_number: "+31-20-555-1012",
    default_address: "Overtoom 215, 1054 HT Amsterdam",  # Amsterdam West
    dietary_preferences: "vegan,gluten-free"
  },
  # Customer on boundary of delivery zones
  %{
    name: "Grens Bewoner",
    email: "boundary@example.nl",
    password: "password123456", 
    role: "customer",
    phone_number: "+31-20-555-1013",
    default_address: "Amstel 86, 1017 AC Amsterdam"  # Just at boundary of delivery radius
  },
  # Test user with multiple addresses
  %{
    name: "Multi Address",
    email: "multi@example.nl",
    password: "password123456", 
    role: "customer",
    phone_number: "+31-20-555-1014",
    default_address: "Prinsengracht 500, 1017 KJ Amsterdam"  # Primary address
    # Additional addresses will be added after user creation
  }
]

customers = 
  Enum.map(customers_data, fn attrs ->
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert!()
    |> User.confirm_changeset() 
    |> Repo.update!()
  end)

IO.puts("Created #{length(customers)} sample customers")

# Add multiple addresses for multi-address test user
multi_user = Enum.find(customers, fn c -> c.email == "multi@example.nl" end)
if multi_user do
  additional_addresses = [
    %{
      "name" => "Work",
      "street_address" => "Zuidas 123, Amsterdam",
      "city" => "Amsterdam",
      "postal_code" => "1082 XX",
      "country" => "Netherlands",
      "latitude" => "52.3380",
      "longitude" => "4.8725", 
      "is_default" => false,
      "user_id" => multi_user.id
    },
    %{
      "name" => "Holiday Home",
      "street_address" => "Strandweg 25, Bergen aan Zee",
      "city" => "Bergen",
      "postal_code" => "1865 TY",
      "country" => "Netherlands",
      "latitude" => "52.6581",
      "longitude" => "4.6288", 
      "is_default" => false,
      "user_id" => multi_user.id
    },
    %{
      "name" => "Parents' House",
      "street_address" => "Hoofdstraat 15, Hilversum",
      "city" => "Hilversum",
      "postal_code" => "1213 ER",
      "country" => "Netherlands",
      "latitude" => "52.2279",
      "longitude" => "5.1693", 
      "is_default" => false,
      "user_id" => multi_user.id
    }
  ]
  
  Enum.each(additional_addresses, fn addr_attrs ->
    Eatfair.Accounts.create_address(addr_attrs)
  end)
  
  IO.puts("Added multiple addresses for test user #{multi_user.email}")
end

# Create courier users
couriers_data = [
  %{
    name: "Max Speedman",
    email: "courier1@example.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1234-5678",
    default_address: "Wibautstraat 150, 1091 GR Amsterdam"  # East Amsterdam
  },
  %{
    name: "Fietskoerier Utrecht",
    email: "courier2@example.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-2345-6789",
    default_address: "Vredenburg 40, 3511 BD Utrecht"  # Central Utrecht
  },
  %{
    name: "Test Courier",
    email: "testcourier@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-9876-5432",
    default_address: "Prins Hendrikkade 33, 1012 TM Amsterdam"  # Central for testing
  }
]

couriers = 
  Enum.map(couriers_data, fn attrs ->
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert!()
    |> User.confirm_changeset() 
    |> Repo.update!()
  end)

IO.puts("Created #{length(couriers)} courier users")

# Create test orders with different statuses for testing order tracking
if Mix.env() == :dev do
  # Create sample order for order tracking testing
  frequent_user = Enum.find(customers, fn c -> c.email == "frequent@example.nl" end)
  italian_restaurant = Enum.find(restaurants, fn r -> r.name == "Bella Italia Amsterdam" end)
  
  if frequent_user && italian_restaurant do
    # Get menu and meals
    italian_menu = 
      Menu
      |> where([m], m.restaurant_id == ^italian_restaurant.id)
      |> limit(1)
      |> Repo.one()
      |> Repo.preload(:meals)

    if italian_menu && length(italian_menu.meals) > 0 do
      # Create orders with different statuses
      order_statuses = ["confirmed", "preparing", "ready", "out_for_delivery", "delivered"]
      
      Enum.each(order_statuses, fn status ->
        # Create order with specific status
        {:ok, order} = Eatfair.Orders.create_order(%{
          customer_id: frequent_user.id,
          restaurant_id: italian_restaurant.id,
          delivery_address: "Herengracht 123, 1015 BR Amsterdam",
          phone_number: frequent_user.phone_number,
          delivery_notes: "Test order with status: #{status}",
          total_price: Decimal.new("35.00"),
          status: status
        })
        
        # Add some items to the order
        meal1 = Enum.at(italian_menu.meals, 0)
        meal2 = Enum.at(italian_menu.meals, 1)
        
        if meal1 && meal2 do
          {:ok, _item1} = Eatfair.Orders.create_order_item(%{
            order_id: order.id,
            meal_id: meal1.id,
            quantity: 1,
            price: meal1.price
          })
          
          {:ok, _item2} = Eatfair.Orders.create_order_item(%{
            order_id: order.id,
            meal_id: meal2.id,
            quantity: 2,
            price: meal2.price
          })
        end
        
        # Create payment for the order
        {:ok, _payment} = Eatfair.Orders.create_payment(%{
          order_id: order.id,
          amount: Decimal.new("35.00"),
          method: "credit_card",
          status: "completed"
        })
      end)
      
      IO.puts("Created test orders with different statuses for #{frequent_user.email}")
    end
  end
end

IO.puts("""

🎉 Enhanced seed data created successfully!

📍 Restaurant locations:
- Amsterdam: Bella Italia, Golden Lotus, Jordaan Bistro  
- Utrecht: Spice Garden, Utrecht Taco Bar

👤 Sample accounts with different roles:

📱 CUSTOMERS:
- Test Customer: test@eatfair.nl / password123456 (Central Amsterdam)
- Regular Customer: piet@example.nl / password123456 (Amsterdam)
- Utrecht Customer: emma@example.nl / password123456 (Utrecht)
- Het Gooi Customer: lisa@example.nl / password123456 (Het Gooi region)
- Frequent Customer: frequent@example.nl / password123456 (With test orders)
- Vegan Customer: vegan@example.nl / password123456 (With dietary preferences)
- Multi-Address User: multi@example.nl / password123456 (With multiple addresses)

🍽️ RESTAURANT OWNERS:
- Bella Italia: marco@bellaitalia.com / password123456
- Golden Lotus: wei@goldenlotus.com / password123456 
- Jordaan Bistro: marie@jordaanbistro.com / password123456
- Spice Garden: raj@spicegarden.com / password123456
- Utrecht Taco: carlos@utrechttaco.com / password123456

🚚 COURIERS:
- Amsterdam Courier: courier1@example.nl / password123456
- Utrecht Courier: courier2@example.nl / password123456
- Test Courier: testcourier@eatfair.nl / password123456

📊 TEST DATA:
- Multiple addresses for multi@example.nl
- Test orders with all status types for frequent@example.nl

🌟 Ready for comprehensive testing across all user journeys!
You can now run: mix phx.server
""")
