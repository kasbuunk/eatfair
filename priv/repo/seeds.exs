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

IO.puts("""

🎉 Geographic seed data created successfully!

📍 Restaurant locations:
- Amsterdam: Bella Italia, Golden Lotus, Jordaan Bistro  
- Utrecht: Spice Garden, Utrecht Taco Bar

👤 Sample accounts:
- Restaurant Owner: marco@bellaitalia.com / password123456
- Customer (Amsterdam): test@eatfair.nl / password123456
- Customer (Utrecht): emma@example.nl / password123456
- Customer (Het Gooi): lisa@example.nl / password123456

🌟 Ready for location-based search testing!
You can now run: mix phx.server
""")
