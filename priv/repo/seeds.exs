# Enhanced Script for populating the database with comprehensive test data
# Run with: mix run priv/repo/enhanced_seeds.exs
#
# This creates realistic production-scale data for testing:
# - 50+ restaurants across multiple regions
# - 200+ users with varied behaviors
# - Hundreds of orders with full history
# - Thousands of reviews
# - Comprehensive courier network
# - Edge cases and realistic scenarios

import Ecto.Query
alias Eatfair.Repo
alias Eatfair.Accounts
alias Eatfair.Accounts.User
alias Eatfair.Restaurants
alias Eatfair.Restaurants.{Restaurant, Cuisine, Menu, Meal}
alias Eatfair.Orders
alias Eatfair.Orders.{Order, OrderItem, Payment}
alias Eatfair.Reviews

# Clear existing data in development
if Mix.env() == :dev do
  IO.puts("🗑️  Clearing existing data...")
  # Delete in dependency order to avoid foreign key constraints
  try do
    Repo.delete_all(from(p in "payments"))
  rescue
    _ -> :ok
  end

  try do
    Repo.delete_all(from(oi in "order_items"))
  rescue
    _ -> :ok
  end

  try do
    Repo.delete_all(from(o in "orders"))
  rescue
    _ -> :ok
  end

  try do
    Repo.delete_all(from(r in "reviews"))
  rescue
    _ -> :ok
  end

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
  IO.puts("✅ Existing data cleared")
end

# ============================================================================
# 0. CREATE ADMIN USERS FOR FEEDBACK SYSTEM ACCESS
# ============================================================================

IO.puts("👑 Creating admin users...")

# Create main admin user for feedback management
admin_users_data = [
  %{
    name: "Admin User",
    email: "admin@eatfair.nl", 
    password: "admin123456789",  # Strong password
    role: "admin",
    phone_number: "+31-20-555-0001"
  },
  %{
    name: "Support Manager", 
    email: "support@eatfair.nl",
    password: "support123456789",
    role: "admin",
    phone_number: "+31-20-555-0002"
  },
  %{
    name: "System Administrator",
    email: "sysadmin@eatfair.nl",
    password: "sysadmin123456789", 
    role: "admin",
    phone_number: "+31-20-555-0003"
  }
]

admin_users = 
  Enum.map(admin_users_data, fn attrs ->
    %User{}
    |> User.registration_changeset(attrs) 
    |> Repo.insert!()
    |> User.confirm_changeset()
    |> Repo.update!()
  end)

IO.puts("✅ Created #{length(admin_users)} admin users:")
Enum.each(admin_users, fn user -> 
  IO.puts("   - #{user.email} (#{user.role})")
end)

# ============================================================================
# 1. CREATE COMPREHENSIVE CUISINES AND FOOD CATEGORIES
# ============================================================================

IO.puts("🍽️  Creating cuisines and food categories...")

cuisines_data = [
  # Traditional Cuisines
  "Italian",
  "Chinese",
  "Mexican",
  "Indian",
  "Thai",
  "Japanese",
  "Mediterranean",
  "American",
  "French",
  "Korean",
  "Vietnamese",
  "Greek",
  "Turkish",
  "Spanish",
  "German",
  "British",
  "Russian",
  "Lebanese",
  "Ethiopian",
  "Moroccan",
  "Brazilian",
  "Peruvian",
  "Caribbean",
  "Scandinavian",
  "Eastern European",

  # Modern Food Categories
  "Healthy Bowls",
  "Pizza",
  "Sushi",
  "Burgers",
  "BBQ",
  "Vegan",
  "Vegetarian",
  "Gluten-Free",
  "Organic",
  "Farm-to-Table",
  "Fusion",
  "Street Food",
  "Comfort Food",
  "Fine Dining",
  "Casual Dining",
  "Fast Casual",
  "Seafood",
  "Steakhouse",
  "Bakery",
  "Desserts",
  "Coffee & Tea",
  "Breakfast & Brunch",
  "Late Night"
]

cuisines =
  Enum.map(cuisines_data, fn name ->
    {:ok, cuisine} = Restaurants.create_cuisine(%{name: name})
    cuisine
  end)

IO.puts("✅ Created #{length(cuisines)} cuisines and categories")

determine_country = fn state_or_province ->
  case state_or_province do
    s
    when s in [
           "NY",
           "CA",
           "TX",
           "FL",
           "IL",
           "PA",
           "OH",
           "MI",
           "GA",
           "NC",
           "NJ",
           "VA",
           "WA",
           "MA",
           "IN",
           "TN",
           "MO",
           "MD",
           "WI",
           "MN",
           "CO",
           "AL",
           "SC",
           "LA",
           "KY",
           "OR",
           "OK",
           "CT",
           "UT",
           "IA",
           "NV",
           "AR",
           "MS",
           "KS",
           "NM",
           "NE",
           "ID",
           "WV",
           "HI",
           "NH",
           "ME",
           "MT",
           "RI",
           "DE",
           "SD",
           "ND",
           "AK",
           "VT",
           "WY",
           "DC"
         ] ->
      "United States"

    p when p in ["ON", "QC", "BC", "AB", "SK", "MB", "NS", "NB", "PE", "NL", "YT", "NT", "NU"] ->
      "Canada"

    # Default for unknown codes
    _ ->
      "United States"
  end
end

# Helper function to parse international addresses
parse_address = fn address_string ->
  # Parse various international formats
  parts = String.split(address_string, ",")

  case parts do
    [street_part, postal_city_part] ->
      city_postal = String.trim(postal_city_part)

      # Dutch postal codes: #### XX City
      case Regex.run(~r/^(\d{4}\s[A-Z]{2})\s(.+)$/, city_postal) do
        [_, postal_code, city] ->
          {String.trim(street_part), String.trim(city), String.trim(postal_code), "Netherlands"}

        _ ->
          # Try North American format: City State/Province Postal
          case Regex.run(~r/^(.+?)\s([A-Z]{2})\s(.+)$/, city_postal) do
            [_, city, state, postal] ->
              {String.trim(street_part), String.trim(city), String.trim(postal),
               determine_country.(state)}

            _ ->
              # European format: Postal City
              case Regex.run(~r/^(\d{4,5})\s(.+)$/, city_postal) do
                [_, postal_code, city] ->
                  {String.trim(street_part), String.trim(city), String.trim(postal_code),
                   "Germany"}

                _ ->
                  # UK format: City Postal
                  case Regex.run(~r/^(.+?)\s([A-Z]{1,2}\d{1,2}\s?\d[A-Z]{2})$/, city_postal) do
                    [_, city, postal] ->
                      {String.trim(street_part), String.trim(city), String.trim(postal),
                       "United Kingdom"}

                    _ ->
                      # Fallback
                      {String.trim(street_part), String.trim(city_postal), "00000", "Netherlands"}
                  end
              end
          end
      end

    [street_part, city_part, country_part] ->
      {String.trim(street_part), String.trim(city_part), "00000", String.trim(country_part)}

    _ ->
      # Fallback for any format
      {address_string, "Amsterdam", "1000 AA", "Netherlands"}
  end
end

# ============================================================================
# 2. GENERATE DOZENS OF RESTAURANTS ACROSS MULTIPLE REGIONS  
# ============================================================================

IO.puts("🏪 Creating restaurants across multiple regions...")

# Restaurant data with heavy Amsterdam concentration, plus international spread
restaurants_data = [
  # ===== AMSTERDAM RESTAURANTS (Heavy concentration for filter testing) =====

  # Central Amsterdam
  %{
    name: "Bella Italia Central",
    address: "Nieuwmarkt 15, 1012 CR Amsterdam",
    latitude: Decimal.new("52.3702"),
    longitude: Decimal.new("4.9002"),
    city: "Amsterdam",
    postal_code: "1012 CR",
    country: "Netherlands",
    avg_preparation_time: 45,
    delivery_radius_km: 8,
    min_order_value: Decimal.new("15.00"),
    image_url:
      "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Italian"],
    description: "Authentic Italian cuisine in the heart of Amsterdam"
  },
  %{
    name: "Golden Lotus Amsterdam",
    address: "Zeedijk 106, 1012 BB Amsterdam",
    latitude: Decimal.new("52.3744"),
    longitude: Decimal.new("4.9006"),
    city: "Amsterdam",
    postal_code: "1012 BB",
    country: "Netherlands",
    avg_preparation_time: 30,
    delivery_radius_km: 6,
    min_order_value: Decimal.new("20.00"),
    image_url:
      "https://static.designmynight.com/uploads/2024/05/Gouqi-London-Chinese-Restaurant-Review.jpg",
    cuisine_names: ["Chinese"],
    description: "Premium Chinese dining experience"
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
    image_url:
      "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["French"],
    description: "Classic French bistro in Amsterdam's charming Jordaan district"
  },

  # Amsterdam East
  %{
    name: "Sushi Tokyo East",
    address: "Weesperstraat 45, 1018 VN Amsterdam",
    latitude: Decimal.new("52.3607"),
    longitude: Decimal.new("4.9118"),
    city: "Amsterdam",
    postal_code: "1018 VN",
    country: "Netherlands",
    avg_preparation_time: 25,
    delivery_radius_km: 5,
    min_order_value: Decimal.new("25.00"),
    image_url:
      "https://images.unsplash.com/photo-1553621042-f6e147245754?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Japanese", "Sushi"],
    description: "Fresh sushi and Japanese delicacies"
  },
  %{
    name: "Healthy Bowl Co.",
    address: "Linnaeusstraat 22, 1093 EK Amsterdam",
    latitude: Decimal.new("52.3656"),
    longitude: Decimal.new("4.9189"),
    city: "Amsterdam",
    postal_code: "1093 EK",
    country: "Netherlands",
    avg_preparation_time: 20,
    delivery_radius_km: 4,
    min_order_value: Decimal.new("12.50"),
    image_url:
      "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Healthy Bowls", "Vegan"],
    description: "Nutritious and delicious healthy bowls"
  },

  # Amsterdam West 
  %{
    name: "Burger Palace Amsterdam",
    address: "Overtoom 150, 1054 HN Amsterdam",
    latitude: Decimal.new("52.3580"),
    longitude: Decimal.new("4.8700"),
    city: "Amsterdam",
    postal_code: "1054 HN",
    country: "Netherlands",
    avg_preparation_time: 15,
    delivery_radius_km: 6,
    min_order_value: Decimal.new("8.00"),
    image_url:
      "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["American", "Burgers"],
    description: "Gourmet burgers made with local ingredients"
  },
  %{
    name: "Spice Route India",
    address: "Kinkerstraat 88, 1053 ED Amsterdam",
    latitude: Decimal.new("52.3676"),
    longitude: Decimal.new("4.8630"),
    city: "Amsterdam",
    postal_code: "1053 ED",
    country: "Netherlands",
    avg_preparation_time: 40,
    delivery_radius_km: 7,
    min_order_value: Decimal.new("18.50"),
    image_url:
      "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Indian"],
    description: "Authentic Indian spices and traditional curries"
  },

  # Amsterdam South
  %{
    name: "Mediterranean Dreams",
    address: "Beethovenstraat 75, 1077 HN Amsterdam",
    latitude: Decimal.new("52.3506"),
    longitude: Decimal.new("4.8813"),
    city: "Amsterdam",
    postal_code: "1077 HN",
    country: "Netherlands",
    avg_preparation_time: 30,
    delivery_radius_km: 8,
    min_order_value: Decimal.new("16.00"),
    image_url:
      "https://images.unsplash.com/photo-1544806846-351ba102b6d5?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Mediterranean", "Greek"],
    description: "Fresh Mediterranean flavors and Greek classics"
  },
  %{
    name: "Thai Garden Amsterdam",
    address: "Van Baerlestraat 120, 1071 BB Amsterdam",
    latitude: Decimal.new("52.3579"),
    longitude: Decimal.new("4.8813"),
    city: "Amsterdam",
    postal_code: "1071 BB",
    country: "Netherlands",
    avg_preparation_time: 35,
    delivery_radius_km: 6,
    min_order_value: Decimal.new("17.50"),
    image_url:
      "https://images.unsplash.com/photo-1559847844-5315695dadae?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Thai"],
    description: "Authentic Thai cuisine with traditional recipes"
  },

  # Amsterdam North (Testing delivery boundaries)
  %{
    name: "Pizza Noord",
    address: "Nieuwendammerdijk 25, 1022 AB Amsterdam",
    latitude: Decimal.new("52.3958"),
    longitude: Decimal.new("4.9145"),
    city: "Amsterdam",
    postal_code: "1022 AB",
    country: "Netherlands",
    avg_preparation_time: 20,
    delivery_radius_km: 10,
    min_order_value: Decimal.new("10.00"),
    image_url:
      "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Italian", "Pizza"],
    description: "Wood-fired pizzas in Amsterdam Noord"
  },

  # ===== UTRECHT RESTAURANTS =====

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
    image_url:
      "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Indian"],
    description: "Traditional Indian spices in historic Utrecht"
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
    image_url:
      "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Mexican"],
    description: "Fresh Mexican tacos and burritos"
  },
  %{
    name: "Canal Cafe Utrecht",
    address: "Stadsbuitengracht 45, 3572 AC Utrecht",
    latitude: Decimal.new("52.0893"),
    longitude: Decimal.new("5.1142"),
    city: "Utrecht",
    postal_code: "3572 AC",
    country: "Netherlands",
    avg_preparation_time: 18,
    delivery_radius_km: 8,
    min_order_value: Decimal.new("9.50"),
    image_url:
      "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Coffee & Tea", "Breakfast & Brunch"],
    description: "Cozy canal-side cafe with fresh pastries"
  },

  # ===== HET GOOI AREA =====

  %{
    name: "Laren Fine Dining",
    address: "Kerkstraat 15, 1251 RE Laren",
    latitude: Decimal.new("52.2564"),
    longitude: Decimal.new("5.2294"),
    city: "Laren",
    postal_code: "1251 RE",
    country: "Netherlands",
    avg_preparation_time: 60,
    delivery_radius_km: 12,
    min_order_value: Decimal.new("35.00"),
    image_url:
      "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Fine Dining", "French"],
    description: "Exquisite fine dining experience in the heart of het Gooi"
  },
  %{
    name: "Hilversum Healthy",
    address: "Hoofdstraat 88, 1213 EX Hilversum",
    latitude: Decimal.new("52.2279"),
    longitude: Decimal.new("5.1693"),
    city: "Hilversum",
    postal_code: "1213 EX",
    country: "Netherlands",
    avg_preparation_time: 25,
    delivery_radius_km: 6,
    min_order_value: Decimal.new("14.00"),
    image_url:
      "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Healthy Bowls", "Vegetarian"],
    description: "Organic and healthy meals in Hilversum"
  },

  # ===== INTERNATIONAL RESTAURANTS (Europe) =====

  %{
    name: "Berlin Currywurst",
    address: "Unter den Linden 45, 10117 Berlin",
    latitude: Decimal.new("52.5170"),
    longitude: Decimal.new("13.3888"),
    city: "Berlin",
    postal_code: "10117",
    country: "Germany",
    avg_preparation_time: 15,
    delivery_radius_km: 8,
    min_order_value: Decimal.new("7.50"),
    image_url:
      "https://images.unsplash.com/photo-1529042410759-befb1204b468?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["German", "Street Food"],
    description: "Authentic Berlin currywurst and German street food"
  },
  %{
    name: "Parisian Crêperie",
    address: "Rue de Rivoli 123, 75001 Paris",
    latitude: Decimal.new("48.8606"),
    longitude: Decimal.new("2.3376"),
    city: "Paris",
    postal_code: "75001",
    country: "France",
    avg_preparation_time: 20,
    delivery_radius_km: 5,
    min_order_value: Decimal.new("11.00"),
    image_url:
      "https://images.unsplash.com/photo-1516975264800-d9c59bd19104?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["French", "Desserts"],
    description: "Traditional French crêpes and galettes"
  },
  %{
    name: "London Fish & Chips",
    address: "Oxford Street 200, W1C 1HE London",
    latitude: Decimal.new("51.5154"),
    longitude: Decimal.new("-0.1426"),
    city: "London",
    postal_code: "W1C 1HE",
    country: "United Kingdom",
    avg_preparation_time: 22,
    delivery_radius_km: 7,
    min_order_value: Decimal.new("12.50"),
    image_url:
      "https://images.unsplash.com/photo-1544468044-75d7b6b5a195?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["British", "Seafood"],
    description: "Traditional British fish & chips in the heart of London"
  },

  # ===== NORTH AMERICAN RESTAURANTS =====

  %{
    name: "Toronto Poutinerie",
    address: "Queen Street West 456, Toronto ON M5V 2A8",
    latitude: Decimal.new("43.6511"),
    longitude: Decimal.new("-79.3470"),
    city: "Toronto",
    postal_code: "M5V 2A8",
    country: "Canada",
    avg_preparation_time: 18,
    delivery_radius_km: 10,
    min_order_value: Decimal.new("8.50"),
    image_url:
      "https://images.unsplash.com/photo-1544468044-75d7b6b5a195?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Canadian", "Comfort Food"],
    description: "Authentic Canadian poutine and comfort food"
  },
  %{
    name: "NYC Pizza Corner",
    address: "Broadway 789, New York NY 10003",
    latitude: Decimal.new("40.7282"),
    longitude: Decimal.new("-73.9942"),
    city: "New York",
    postal_code: "10003",
    country: "United States",
    avg_preparation_time: 12,
    delivery_radius_km: 6,
    min_order_value: Decimal.new("10.00"),
    image_url:
      "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["American", "Pizza"],
    description: "Authentic New York style pizza by the slice"
  },

  # ===== EDGE CASES AND UNUSUAL RESTAURANTS =====

  # Restaurant with minimal info (testing incomplete data)
  %{
    name: "Mystery Kitchen",
    address: "Somewhere 1, 1000 XX Amsterdam",
    latitude: Decimal.new("52.3676"),
    longitude: Decimal.new("4.9041"),
    city: "Amsterdam",
    postal_code: "1000 XX",
    country: "Netherlands",
    avg_preparation_time: 45,
    delivery_radius_km: 3,
    min_order_value: Decimal.new("20.00"),
    # No image_url, no description
    cuisine_names: ["Fusion"],
    description: nil
  },

  # Restaurant at exact boundary (for delivery testing)
  %{
    name: "Boundary Bistro",
    address: "Amstel 300, 1017 AK Amsterdam",
    latitude: Decimal.new("52.3611"),
    longitude: Decimal.new("4.8914"),
    city: "Amsterdam",
    postal_code: "1017 AK",
    country: "Netherlands",
    avg_preparation_time: 30,
    delivery_radius_km: 5,
    min_order_value: Decimal.new("15.00"),
    image_url:
      "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["European"],
    description: "Located exactly at delivery boundaries for testing"
  },

  # Restaurant with very large delivery radius
  %{
    name: "Wide Delivery Pizza",
    address: "Centraal Station 1, 1012 AB Amsterdam",
    latitude: Decimal.new("52.3791"),
    longitude: Decimal.new("4.9003"),
    city: "Amsterdam",
    postal_code: "1012 AB",
    country: "Netherlands",
    avg_preparation_time: 25,
    delivery_radius_km: 25,
    min_order_value: Decimal.new("12.00"),
    image_url:
      "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Pizza"],
    description: "Pizza delivery with unusually wide coverage area"
  },

  # Very expensive restaurant
  %{
    name: "Michelin Star Deluxe",
    address: "Museum Quarter 50, 1071 DJ Amsterdam",
    latitude: Decimal.new("52.3579"),
    longitude: Decimal.new("4.8813"),
    city: "Amsterdam",
    postal_code: "1071 DJ",
    country: "Netherlands",
    avg_preparation_time: 90,
    delivery_radius_km: 4,
    min_order_value: Decimal.new("75.00"),
    image_url:
      "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Fine Dining"],
    description: "Exclusive Michelin-starred cuisine for special occasions"
  },

  # Very cheap/fast restaurant  
  %{
    name: "Quick Bite Express",
    address: "Station Plaza 10, 1012 AB Amsterdam",
    latitude: Decimal.new("52.3791"),
    longitude: Decimal.new("4.9003"),
    city: "Amsterdam",
    postal_code: "1012 AB",
    country: "Netherlands",
    avg_preparation_time: 8,
    delivery_radius_km: 3,
    min_order_value: Decimal.new("5.00"),
    image_url:
      "https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Fast Casual"],
    description: "Quick and affordable meals for busy people"
  },

  # Late night restaurant
  %{
    name: "After Midnight Kitchen",
    address: "Leidseplein 25, 1017 PS Amsterdam",
    latitude: Decimal.new("52.3639"),
    longitude: Decimal.new("4.8837"),
    city: "Amsterdam",
    postal_code: "1017 PS",
    country: "Netherlands",
    avg_preparation_time: 20,
    delivery_radius_km: 8,
    min_order_value: Decimal.new("13.50"),
    image_url:
      "https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=400&h=300&fit=crop&crop=center",
    cuisine_names: ["Late Night", "Comfort Food"],
    description: "Open until 4 AM for late-night cravings"
  }
]

# Create restaurant owners for each restaurant
IO.puts("👨‍🍳 Creating restaurant owners...")

# Helper to generate realistic names by region
generate_restaurant_owner = fn restaurant_data, index ->
  case restaurant_data.country do
    "Netherlands" ->
      dutch_names = [
        "Jan de Kok",
        "Marie van der Berg",
        "Pieter Janssen",
        "Emma de Vries",
        "Lukas Bakker",
        "Sophie Hendriks",
        "Marco Rossi",
        "Wei Chen",
        "Ahmed Hassan",
        "Priya Patel"
      ]

      %{
        name: Enum.at(dutch_names, rem(index, length(dutch_names))),
        email:
          "owner#{index}@#{String.downcase(String.replace(restaurant_data.name, ~r/\s+/, ""))}.nl",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+31-20-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }

    "Germany" ->
      %{
        name: "Hans Mueller",
        email:
          "owner#{index}@#{String.downcase(String.replace(restaurant_data.name, ~r/\s+/, ""))}.de",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+49-30-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }

    "France" ->
      %{
        name: "Pierre Dubois",
        email:
          "owner#{index}@#{String.downcase(String.replace(restaurant_data.name, ~r/\s+/, ""))}.fr",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+33-1-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }

    "United Kingdom" ->
      %{
        name: "James Smith",
        email:
          "owner#{index}@#{String.downcase(String.replace(restaurant_data.name, ~r/\s+/, ""))}.co.uk",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+44-20-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }

    "Canada" ->
      %{
        name: "Sarah Johnson",
        email:
          "owner#{index}@#{String.downcase(String.replace(restaurant_data.name, ~r/\s+/, ""))}.ca",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+1-416-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }

    "United States" ->
      %{
        name: "Michael Davis",
        email:
          "owner#{index}@#{String.downcase(String.replace(restaurant_data.name, ~r/\s+/, ""))}.com",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+1-212-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }

    _ ->
      %{
        name: "Restaurant Owner #{index}",
        email: "owner#{index}@restaurant.com",
        password: "password123456",
        role: "restaurant_owner",
        phone_number: "+31-20-555-#{String.pad_leading(to_string(1000 + index), 4, "0")}"
      }
  end
end

restaurant_owners =
  restaurants_data
  |> Enum.with_index()
  |> Enum.map(fn {restaurant_data, index} ->
    generate_restaurant_owner.(restaurant_data, index)
  end)

owners =
  Enum.map(restaurant_owners, fn attrs ->
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert!()
    |> User.confirm_changeset()
    |> Repo.update!()
  end)

IO.puts("✅ Created #{length(owners)} restaurant owners")

# Create restaurants
IO.puts("🏪 Creating restaurants...")

restaurants =
  restaurants_data
  |> Enum.with_index()
  |> Enum.map(fn {%{cuisine_names: cuisine_names} = attrs, index} ->
    attrs =
      attrs
      |> Map.delete(:cuisine_names)
      |> Map.put(:owner_id, Enum.at(owners, index).id)

    {:ok, restaurant} = Restaurants.create_restaurant(attrs)

    # Associate with cuisines
    restaurant_cuisines =
      Enum.map(cuisine_names, fn name ->
        cuisine = Enum.find(cuisines, fn c -> c.name == name end)

        if cuisine do
          %{
            restaurant_id: restaurant.id,
            cuisine_id: cuisine.id,
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
        end
      end)
      # Remove nils
      |> Enum.filter(& &1)

    if length(restaurant_cuisines) > 0 do
      Repo.insert_all("restaurant_cuisines", restaurant_cuisines)
    end

    restaurant
  end)

IO.puts("✅ Created #{length(restaurants)} restaurants")

# ============================================================================
# 3. CREATE HUNDREDS OF DIVERSE USERS WITH REALISTIC PROFILES
# ============================================================================

IO.puts("👥 Creating diverse user base...")

# Generate realistic customer data with varied behaviors
customers_data = [
  # ===== AMSTERDAM CUSTOMERS (Heavy concentration) =====

  # Very active customers (for loyalty testing)
  %{
    name: "Jan de Frequent",
    email: "frequent@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-1001",
    default_address: "Herengracht 123, 1015 BR Amsterdam",
    dietary_preferences: "none",
    loyalty_level: "gold",
    avg_monthly_orders: 25
  },
  %{
    name: "Emma de Foodie",
    email: "foodie@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-1002",
    default_address: "Prinsenstraat 45, 1015 DC Amsterdam",
    dietary_preferences: "vegetarian",
    loyalty_level: "gold",
    avg_monthly_orders: 20
  },
  %{
    name: "Marco the Explorer",
    email: "explorer@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-1003",
    default_address: "Jordaan District 88, 1016 PH Amsterdam",
    dietary_preferences: "none",
    loyalty_level: "silver",
    avg_monthly_orders: 15
  },

  # Regular customers
  %{
    name: "Sophie Vegano",
    email: "vegan@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-1004",
    default_address: "Overtoom 215, 1054 HT Amsterdam",
    dietary_preferences: "vegan,gluten-free",
    loyalty_level: "silver",
    avg_monthly_orders: 12
  },
  %{
    name: "Piet van Amsterdam",
    email: "piet@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-1005",
    default_address: "Damrak 70, 1012 LM Amsterdam",
    dietary_preferences: "none",
    loyalty_level: "bronze",
    avg_monthly_orders: 8
  },
  %{
    name: "Lisa Healthy",
    email: "healthy@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-1006",
    default_address: "Museumplein 20, 1071 DJ Amsterdam",
    dietary_preferences: "organic,low-carb",
    loyalty_level: "silver",
    avg_monthly_orders: 10
  },

  # Occasional customers
  %{
    name: "Tourist Tom",
    email: "tourist@example.com",
    password: "password123456",
    role: "customer",
    phone_number: "+1-555-000-1234",
    default_address: "Hotel Central 1, 1012 AA Amsterdam",
    dietary_preferences: "none",
    loyalty_level: "none",
    avg_monthly_orders: 2
  },
  %{
    name: "Student Sarah",
    email: "student@student.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-6-1234-5678",
    default_address: "Campus Housing 42, 1098 XG Amsterdam",
    dietary_preferences: "budget-friendly",
    loyalty_level: "bronze",
    avg_monthly_orders: 6
  },

  # ===== UTRECHT CUSTOMERS =====

  %{
    name: "Emma Janssen",
    email: "emma@utrecht.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-30-555-2001",
    default_address: "Lange Nieuwstraat 22, 3512 PH Utrecht",
    dietary_preferences: "vegetarian",
    loyalty_level: "silver",
    avg_monthly_orders: 12
  },
  %{
    name: "Utrecht University Student",
    email: "utrechtstudent@uu.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-30-555-2002",
    default_address: "Campus Uithof 100, 3584 CS Utrecht",
    dietary_preferences: "halal",
    loyalty_level: "bronze",
    avg_monthly_orders: 8
  },

  # ===== HET GOOI CUSTOMERS =====

  %{
    name: "Lisa de Vries",
    email: "lisa@hetgooi.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-35-555-3001",
    default_address: "Kerkstraat 15, 1251 RE Laren",
    dietary_preferences: "organic",
    loyalty_level: "gold",
    avg_monthly_orders: 18
  },
  %{
    name: "Hilversum Familie",
    email: "familie@hilversum.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-35-555-3002",
    default_address: "Hoofdstraat 88, 1213 EX Hilversum",
    dietary_preferences: "family-friendly",
    loyalty_level: "silver",
    avg_monthly_orders: 15
  },

  # ===== INTERNATIONAL CUSTOMERS =====

  %{
    name: "Hans Müller",
    email: "hans@berlin.de",
    password: "password123456",
    role: "customer",
    phone_number: "+49-30-555-4001",
    default_address: "Alexanderplatz 5, 10178 Berlin",
    dietary_preferences: "none",
    loyalty_level: "bronze",
    avg_monthly_orders: 5
  },
  %{
    name: "Marie Dubois",
    email: "marie@paris.fr",
    password: "password123456",
    role: "customer",
    phone_number: "+33-1-555-4002",
    default_address: "Champs Élysées 100, 75008 Paris",
    dietary_preferences: "french-cuisine-lover",
    loyalty_level: "silver",
    avg_monthly_orders: 10
  },
  %{
    name: "James Smith",
    email: "james@london.co.uk",
    password: "password123456",
    role: "customer",
    phone_number: "+44-20-555-4003",
    default_address: "Baker Street 221B, NW1 6XE London",
    dietary_preferences: "traditional-british",
    loyalty_level: "bronze",
    avg_monthly_orders: 7
  },
  %{
    name: "Sarah Johnson",
    email: "sarah@toronto.ca",
    password: "password123456",
    role: "customer",
    phone_number: "+1-416-555-4004",
    default_address: "CN Tower Street 290, Toronto ON M5V 3A8",
    dietary_preferences: "maple-syrup-addict",
    loyalty_level: "gold",
    avg_monthly_orders: 22
  },
  %{
    name: "Mike Davis",
    email: "mike@nyc.com",
    password: "password123456",
    role: "customer",
    phone_number: "+1-212-555-4005",
    default_address: "Times Square 1, New York NY 10036",
    dietary_preferences: "pizza-lover",
    loyalty_level: "silver",
    avg_monthly_orders: 16
  },

  # ===== EDGE CASE CUSTOMERS =====

  # Customer with multiple addresses
  %{
    name: "Multi Address User",
    email: "multi@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-5001",
    default_address: "Prinsengracht 500, 1017 KJ Amsterdam",
    dietary_preferences: "none",
    loyalty_level: "gold",
    avg_monthly_orders: 20
  },

  # Boundary customer (testing delivery limits)
  %{
    name: "Grens Bewoner",
    email: "boundary@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-5002",
    default_address: "Amstel 86, 1017 AC Amsterdam",
    dietary_preferences: "boundary-tester",
    loyalty_level: "bronze",
    avg_monthly_orders: 4
  },

  # Customer with incomplete profile
  %{
    name: "Incomplete Profile",
    email: "incomplete@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: nil,
    default_address: nil,
    dietary_preferences: nil,
    loyalty_level: "none",
    avg_monthly_orders: 1
  },

  # VIP customer (for testing high-value scenarios) 
  %{
    name: "VIP Customer",
    email: "vip@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-5003",
    default_address: "Luxury District 1, 1071 AA Amsterdam",
    dietary_preferences: "fine-dining-only",
    loyalty_level: "platinum",
    avg_monthly_orders: 30
  },

  # Test customer for manual testing
  %{
    name: "Test Customer",
    email: "test@eatfair.nl",
    password: "password123456",
    role: "customer",
    phone_number: "+31-20-555-9999",
    default_address: "Leidseplein 12, 1017 PT Amsterdam",
    dietary_preferences: "testing",
    loyalty_level: "gold",
    avg_monthly_orders: 50
  }
]

# Add many more customers with varied patterns (generate programmatically)
# Generate 180 additional customers for 200 total
additional_customers =
  1..180
  |> Enum.map(fn i ->
    # Vary by region
    {city, postal_code, country, phone_prefix} =
      case rem(i, 10) do
        x when x in 0..6 ->
          {"Amsterdam",
           "#{1000 + rem(i, 100)} #{[:AA, :BB, :CC, :DD, :EE, :FF, :GG, :HH] |> Enum.at(rem(i, 8))}",
           "Netherlands", "+31-20"}

        7 ->
          {"Utrecht", "35#{10 + rem(i, 90)} #{[:AB, :BC, :CD] |> Enum.at(rem(i, 3))}",
           "Netherlands", "+31-30"}

        8 ->
          {"Hilversum", "12#{10 + rem(i, 90)} #{[:EX, :ER, :ES] |> Enum.at(rem(i, 3))}",
           "Netherlands", "+31-35"}

        9 ->
          case rem(i, 4) do
            0 ->
              {"Berlin", "#{10000 + rem(i, 1000)}", "Germany", "+49-30"}

            1 ->
              {"Paris", "750#{rem(i, 20) |> Integer.to_string() |> String.pad_leading(2, "0")}",
               "France", "+33-1"}

            2 ->
              {"London",
               "#{[:SW, :NW, :SE, :NE] |> Enum.at(rem(i, 4))}#{rem(i, 10)} #{rem(i, 9)}#{[:AA, :BB, :CC] |> Enum.at(rem(i, 3))}",
               "United Kingdom", "+44-20"}

            3 ->
              {"Toronto", "M#{rem(i, 9) + 1}V #{rem(i, 9)}A#{rem(i, 9)}", "Canada", "+1-416"}
          end
      end

    # Vary dietary preferences
    dietary_preferences =
      [
        "none",
        "vegetarian",
        "vegan",
        "gluten-free",
        "halal",
        "kosher",
        "low-carb",
        "organic",
        "spicy-food-lover",
        "no-seafood",
        "nut-allergy",
        "dairy-free",
        "keto",
        "mediterranean",
        "asian-cuisine-lover",
        "comfort-food"
      ]
      |> Enum.at(rem(i, 16))

    # Vary loyalty levels and order frequency
    {loyalty_level, avg_monthly_orders} =
      case rem(i, 20) do
        # 25% inactive users
        x when x in 0..4 -> {"none", rem(i, 3) + 1}
        # 30% bronze 
        x when x in 5..10 -> {"bronze", rem(i, 6) + 3}
        # 25% silver
        x when x in 11..15 -> {"silver", rem(i, 8) + 6}
        # 15% gold
        x when x in 16..18 -> {"gold", rem(i, 10) + 12}
        # 5% platinum
        19 -> {"platinum", rem(i, 15) + 20}
      end

    %{
      name: "Customer #{String.pad_leading(to_string(i), 3, "0")}",
      email: "customer#{String.pad_leading(to_string(i), 3, "0")}@#{String.downcase(city)}.com",
      password: "password123456",
      role: "customer",
      phone_number: "#{phone_prefix}-555-#{String.pad_leading(to_string(6000 + i), 4, "0")}",
      default_address: "Street #{i * 2}, #{postal_code} #{city}",
      dietary_preferences: dietary_preferences,
      loyalty_level: loyalty_level,
      avg_monthly_orders: avg_monthly_orders
    }
  end)

all_customers_data = customers_data ++ additional_customers

customers =
  Enum.map(all_customers_data, fn attrs ->
    # Remove custom fields not in User schema
    user_attrs = attrs |> Map.drop([:dietary_preferences, :loyalty_level, :avg_monthly_orders])

    %User{}
    |> User.registration_changeset(user_attrs)
    |> Repo.insert!()
    |> User.confirm_changeset()
    |> Repo.update!()
  end)

IO.puts("✅ Created #{length(customers)} diverse customers")

# Create Address records for customers with default_address
IO.puts("🏠 Creating customer addresses...")

customers_with_addresses = Enum.zip(customers, all_customers_data)

Enum.each(customers_with_addresses, fn {user, customer_data} ->
  if user.default_address && String.trim(user.default_address) != "" do
    {street, city, postal_code, country} = parse_address.(user.default_address)

    case Eatfair.Accounts.create_address(%{
           "name" => "Home",
           "street_address" => street,
           "city" => city,
           "postal_code" => postal_code,
           "country" => country,
           "is_default" => true,
           "user_id" => user.id
         }) do
      {:ok, _addr} ->
        :ok

      {:error, changeset} ->
        IO.puts("⚠️ Failed to create address for #{user.email}: #{inspect(changeset.errors)}")
    end
  end
end)

# Add multiple addresses for specific test users
multi_user = Enum.find(customers, fn c -> c.email == "multi@eatfair.nl" end)

if multi_user do
  additional_addresses = [
    %{
      "name" => "Work",
      "street_address" => "Business District 100",
      "city" => "Amsterdam",
      "postal_code" => "1082 XX",
      "country" => "Netherlands",
      "latitude" => "52.3380",
      "longitude" => "4.8725",
      "is_default" => false,
      "user_id" => multi_user.id
    },
    %{
      "name" => "Weekend House",
      "street_address" => "Countryside 25",
      "city" => "Laren",
      "postal_code" => "1251 AB",
      "country" => "Netherlands",
      "latitude" => "52.2564",
      "longitude" => "5.2294",
      "is_default" => false,
      "user_id" => multi_user.id
    },
    %{
      "name" => "Parents House",
      "street_address" => "Family Street 15",
      "city" => "Utrecht",
      "postal_code" => "3500 AA",
      "country" => "Netherlands",
      "latitude" => "52.0907",
      "longitude" => "5.1214",
      "is_default" => false,
      "user_id" => multi_user.id
    }
  ]

  Enum.each(additional_addresses, fn addr_attrs ->
    Eatfair.Accounts.create_address(addr_attrs)
  end)

  IO.puts("Added multiple addresses for multi-address user")
end

IO.puts("✅ Created addresses for all customers")

# ============================================================================
# 4. BUILD COMPREHENSIVE MENU SYSTEMS FOR ALL RESTAURANTS
# ============================================================================

IO.puts("🍽️ Creating diverse menu systems...")

# Generate comprehensive menus with varied structures
comprehensive_menu_data = [
  # Italian restaurants with varied menu sizes
  %{
    restaurant: "Bella Italia Central",
    menus: [
      %{
        name: "Appetizers",
        meals: [
          %{
            name: "Bruschetta al Pomodoro",
            description: "Grilled bread with fresh tomatoes, garlic, and basil",
            price: 8.50,
            is_available: true
          },
          %{
            name: "Antipasto Misto",
            description: "Selection of cured meats, cheeses, and marinated vegetables",
            price: 14.00,
            is_available: true
          },
          %{
            name: "Arancini Siciliani",
            description: "Fried rice balls with ragù and mozzarella",
            price: 9.50,
            is_available: true
          },
          # Seasonal unavailable
          %{
            name: "Burrata Pugliese",
            description: "Creamy burrata with tomatoes and basil",
            price: 12.00,
            is_available: false
          }
        ]
      },
      %{
        name: "Pasta & Risotto",
        meals: [
          %{
            name: "Spaghetti Carbonara",
            description: "Classic Roman pasta with eggs, pecorino, and pancetta",
            price: 18.50,
            is_available: true
          },
          %{
            name: "Penne all'Arrabbiata",
            description: "Spicy tomato sauce with garlic and red pepper",
            price: 16.00,
            is_available: true
          },
          %{
            name: "Risotto ai Porcini",
            description: "Creamy arborio rice with porcini mushrooms",
            price: 22.00,
            is_available: true
          },
          %{
            name: "Linguine alle Vongole",
            description: "Linguine with fresh clams in white wine sauce",
            price: 24.00,
            is_available: true
          },
          %{
            name: "Gnocchi alla Sorrentina",
            description: "Potato dumplings with tomato, mozzarella, and basil",
            price: 17.50,
            is_available: true
          }
        ]
      },
      %{
        name: "Pizza",
        meals: [
          %{
            name: "Margherita",
            description: "San Marzano tomatoes, buffalo mozzarella, fresh basil",
            price: 16.00,
            is_available: true
          },
          %{
            name: "Diavola",
            description: "Spicy salami, tomato sauce, mozzarella, oregano",
            price: 18.50,
            is_available: true
          },
          %{
            name: "Quattro Stagioni",
            description: "Four seasons: mushrooms, artichokes, ham, olives",
            price: 20.00,
            is_available: true
          },
          %{
            name: "Prosciutto e Funghi",
            description: "Ham, mushrooms, tomato, mozzarella",
            price: 19.00,
            is_available: true
          },
          %{
            name: "Pizza Bianca",
            description: "White pizza with ricotta, mozzarella, and rosemary",
            price: 17.00,
            is_available: true
          }
        ]
      },
      %{
        name: "Main Courses",
        meals: [
          %{
            name: "Osso Buco alla Milanese",
            description: "Braised veal shanks with saffron risotto",
            price: 32.00,
            is_available: true
          },
          %{
            name: "Saltimbocca alla Romana",
            description: "Veal with prosciutto and sage in white wine",
            price: 28.00,
            is_available: true
          },
          # Chef special
          %{
            name: "Branzino in Crosta",
            description: "Sea bass baked in herb crust with roasted vegetables",
            price: 26.00,
            is_available: false
          }
        ]
      },
      %{
        name: "Desserts",
        meals: [
          %{
            name: "Tiramisu",
            description: "Classic coffee-flavored dessert with mascarpone",
            price: 7.50,
            is_available: true
          },
          %{
            name: "Panna Cotta",
            description: "Vanilla cream dessert with berry coulis",
            price: 6.50,
            is_available: true
          },
          %{
            name: "Cannoli Siciliani",
            description: "Traditional Sicilian pastry with ricotta cream",
            price: 8.00,
            is_available: true
          }
        ]
      }
    ]
  },

  # Chinese restaurant with extensive menu
  %{
    restaurant: "Golden Lotus Amsterdam",
    menus: [
      %{
        name: "Dim Sum & Appetizers",
        meals: [
          %{
            name: "Har Gow",
            description: "Steamed shrimp dumplings with translucent wrapper",
            price: 6.50,
            is_available: true
          },
          %{
            name: "Siu Mai",
            description: "Steamed pork and shrimp dumplings",
            price: 6.00,
            is_available: true
          },
          %{
            name: "Char Siu Bao",
            description: "BBQ pork steamed buns",
            price: 7.00,
            is_available: true
          },
          %{
            name: "Spring Rolls (4 pieces)",
            description: "Crispy vegetable spring rolls",
            price: 8.50,
            is_available: true
          },
          %{
            name: "Peking Duck Pancakes",
            description: "Crispy duck with hoisin sauce and pancakes",
            price: 16.00,
            is_available: true
          }
        ]
      },
      %{
        name: "Soups",
        meals: [
          %{
            name: "Hot & Sour Soup",
            description: "Traditional Sichuan soup with tofu and mushrooms",
            price: 5.50,
            is_available: true
          },
          %{
            name: "Wonton Soup",
            description: "Pork and shrimp wontons in clear broth",
            price: 7.50,
            is_available: true
          },
          # Luxury item
          %{
            name: "Shark Fin Soup",
            description: "Premium soup with shark fin (synthetic)",
            price: 18.00,
            is_available: false
          }
        ]
      },
      %{
        name: "Poultry & Meat",
        meals: [
          %{
            name: "Kung Pao Chicken",
            description: "Diced chicken with peanuts and dried chilies",
            price: 15.50,
            is_available: true
          },
          %{
            name: "General Tso's Chicken",
            description: "Crispy chicken in sweet and spicy sauce",
            price: 16.50,
            is_available: true
          },
          %{
            name: "Sweet and Sour Pork",
            description: "Battered pork with pineapple and peppers",
            price: 16.50,
            is_available: true
          },
          %{
            name: "Mapo Tofu",
            description: "Silky tofu in spicy Sichuan sauce",
            price: 13.50,
            is_available: true
          },
          %{
            name: "Peking Duck Half",
            description: "Half roasted duck with pancakes and sauce",
            price: 32.00,
            is_available: true
          }
        ]
      },
      %{
        name: "Seafood",
        meals: [
          %{
            name: "Salt & Pepper Prawns",
            description: "Crispy prawns with jalapeños and onions",
            price: 22.00,
            is_available: true
          },
          %{
            name: "Steamed Fish",
            description: "Fresh fish steamed with ginger and soy sauce",
            price: 24.00,
            is_available: true
          },
          %{
            name: "Szechuan Fish",
            description: "Fish fillets in spicy Szechuan broth",
            price: 21.00,
            is_available: true
          }
        ]
      },
      %{
        name: "Rice & Noodles",
        meals: [
          %{
            name: "Yang Chow Fried Rice",
            description: "Fried rice with shrimp, char siu, and eggs",
            price: 12.50,
            is_available: true
          },
          %{
            name: "Beef Lo Mein",
            description: "Soft egg noodles with beef and vegetables",
            price: 14.00,
            is_available: true
          },
          %{
            name: "Dan Dan Noodles",
            description: "Spicy Szechuan noodles with minced pork",
            price: 13.50,
            is_available: true
          },
          %{
            name: "Singapore Rice Noodles",
            description: "Curry-flavored rice noodles with shrimp",
            price: 15.00,
            is_available: true
          }
        ]
      }
    ]
  },

  # Sushi restaurant with precise menu
  %{
    restaurant: "Sushi Tokyo East",
    menus: [
      %{
        name: "Nigiri Sushi (2 pieces)",
        meals: [
          %{
            name: "Tuna (Maguro)",
            description: "Fresh bluefin tuna",
            price: 8.50,
            is_available: true
          },
          %{
            name: "Salmon (Sake)",
            description: "Norwegian salmon",
            price: 7.50,
            is_available: true
          },
          %{
            name: "Yellowtail (Hamachi)",
            description: "Japanese yellowtail",
            price: 9.00,
            is_available: true
          },
          # Premium seasonal
          %{
            name: "Sea Urchin (Uni)",
            description: "Premium sea urchin from Hokkaido",
            price: 15.00,
            is_available: false
          },
          %{
            name: "Eel (Unagi)",
            description: "Grilled eel with sweet sauce",
            price: 10.00,
            is_available: true
          },
          %{
            name: "Shrimp (Ebi)",
            description: "Cooked tiger shrimp",
            price: 6.50,
            is_available: true
          }
        ]
      },
      %{
        name: "Maki Rolls (8 pieces)",
        meals: [
          %{
            name: "California Roll",
            description: "Crab, avocado, cucumber, sesame",
            price: 9.50,
            is_available: true
          },
          %{
            name: "Spicy Tuna Roll",
            description: "Spicy tuna with cucumber",
            price: 11.00,
            is_available: true
          },
          %{
            name: "Philadelphia Roll",
            description: "Salmon, cream cheese, avocado",
            price: 12.00,
            is_available: true
          },
          %{
            name: "Dragon Roll",
            description: "Eel, cucumber topped with avocado",
            price: 16.00,
            is_available: true
          }
        ]
      },
      %{
        name: "Sashimi (5 pieces)",
        meals: [
          %{
            name: "Tuna Sashimi",
            description: "Fresh bluefin tuna slices",
            price: 14.00,
            is_available: true
          },
          %{
            name: "Salmon Sashimi",
            description: "Norwegian salmon slices",
            price: 12.50,
            is_available: true
          },
          %{
            name: "Mixed Sashimi",
            description: "Chef's selection of 5 different fish",
            price: 22.00,
            is_available: true
          }
        ]
      }
    ]
  },

  # Minimal menu restaurant (edge case)
  %{
    restaurant: "Mystery Kitchen",
    menus: [
      %{
        name: "Limited Menu",
        meals: [
          # No description
          %{name: "Mystery Dish", description: nil, price: 25.00, is_available: true},
          # Unavailable
          %{
            name: "Secret Recipe",
            description: "Chef's special - ingredients are a surprise",
            price: 30.00,
            is_available: false
          }
        ]
      }
    ]
  },

  # Extensive menu restaurant (stress test)
  %{
    restaurant: "Wide Delivery Pizza",
    menus: [
      %{
        name: "Traditional Pizzas",
        meals:
          1..20
          |> Enum.map(fn i ->
            %{
              name: "Pizza Special #{i}",
              description: "Pizza with #{i} different toppings including special sauce",
              price: Decimal.new("#{10 + i}.50"),
              # Make some unavailable
              is_available: rem(i, 7) != 0
            }
          end)
      },
      %{
        name: "Gourmet Pizzas",
        meals:
          1..15
          |> Enum.map(fn i ->
            %{
              name: "Gourmet Creation #{i}",
              description: "Premium ingredients with artisanal #{i}-hour preparation",
              price: Decimal.new("#{20 + i * 2}.00"),
              is_available: true
            }
          end)
      }
    ]
  }
]

# Add simple menus for remaining restaurants to ensure all have food
# Skip the ones we defined above
remaining_restaurants = restaurants |> Enum.drop(5)

simple_menus =
  remaining_restaurants
  |> Enum.map(fn restaurant ->
    # Generate simple menu based on restaurant cuisine
    base_meals =
      case String.contains?(restaurant.name, ["French", "Bistro"]) do
        true ->
          [
            %{
              name: "French Onion Soup",
              description: "Classic soup with gruyere cheese",
              price: 8.50,
              is_available: true
            },
            %{
              name: "Coq au Vin",
              description: "Chicken braised in red wine",
              price: 24.00,
              is_available: true
            },
            %{
              name: "Ratatouille",
              description: "Traditional vegetable stew from Provence",
              price: 16.50,
              is_available: true
            }
          ]

        _ ->
          case String.contains?(restaurant.name, ["Burger", "American"]) do
            true ->
              [
                %{
                  name: "Classic Burger",
                  description: "Beef patty with lettuce, tomato, cheese",
                  price: 12.00,
                  is_available: true
                },
                %{
                  name: "BBQ Bacon Burger",
                  description: "Burger with bacon and BBQ sauce",
                  price: 14.50,
                  is_available: true
                },
                %{
                  name: "Veggie Burger",
                  description: "Plant-based patty with avocado",
                  price: 11.50,
                  is_available: true
                }
              ]

            _ ->
              case String.contains?(restaurant.name, ["Healthy", "Bowl"]) do
                true ->
                  [
                    %{
                      name: "Buddha Bowl",
                      description: "Quinoa, vegetables, and tahini dressing",
                      price: 13.50,
                      is_available: true
                    },
                    %{
                      name: "Acai Bowl",
                      description: "Acai with granola, berries, and honey",
                      price: 11.00,
                      is_available: true
                    },
                    %{
                      name: "Green Goddess Bowl",
                      description: "Kale, avocado, hemp seeds, green goddess dressing",
                      price: 12.50,
                      is_available: true
                    }
                  ]

                _ ->
                  [
                    # Generic menu for any restaurant
                    %{
                      name: "Chef's Special",
                      description: "Daily special prepared by our chef",
                      price: 18.50,
                      is_available: true
                    },
                    %{
                      name: "House Salad",
                      description: "Fresh mixed greens with house dressing",
                      price: 9.50,
                      is_available: true
                    },
                    %{
                      name: "Signature Dish",
                      description: "Our restaurant's signature creation",
                      price: 22.00,
                      is_available: true
                    }
                  ]
              end
          end
      end

    %{
      restaurant: restaurant.name,
      menus: [
        %{
          name: "Main Menu",
          meals: base_meals
        }
      ]
    }
  end)

all_menu_data = comprehensive_menu_data ++ simple_menus

# Create menus and meals for all restaurants
Enum.each(all_menu_data, fn %{restaurant: restaurant_name, menus: menus_data} ->
  restaurant = Enum.find(restaurants, fn r -> r.name == restaurant_name end)

  if restaurant do
    Enum.each(menus_data, fn %{name: menu_name, meals: meals_data} ->
      {:ok, menu} =
        Repo.insert(%Menu{
          name: menu_name,
          restaurant_id: restaurant.id
        })

      Enum.each(meals_data, fn meal_attrs ->
        Repo.insert!(%Meal{
          name: meal_attrs.name,
          description: meal_attrs.description,
          price: meal_attrs.price,
          menu_id: menu.id,
          is_available: meal_attrs.is_available
        })
      end)
    end)
  end
end)

IO.puts("✅ Created comprehensive menu systems for all restaurants")

# ============================================================================
# 5. ESTABLISH COURIER NETWORK WITH REALISTIC AVAILABILITY
# ============================================================================

IO.puts("🚚 Creating courier network...")

# Create diverse courier users
courier_data = [
  # Amsterdam couriers (heavy concentration)
  %{
    name: "Max Speedman",
    email: "courier.max@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-1001",
    default_address: "Wibautstraat 150, 1091 GR Amsterdam",
    status: "active",
    vehicle: "bicycle",
    coverage_area: "amsterdam-center"
  },
  %{
    name: "Lisa Lightning",
    email: "courier.lisa@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-1002",
    default_address: "Overtoom 88, 1054 HK Amsterdam",
    status: "active",
    vehicle: "e-bike",
    coverage_area: "amsterdam-west"
  },
  %{
    name: "Ahmed Express",
    email: "courier.ahmed@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-1003",
    default_address: "Linnaeusstraat 44, 1093 EL Amsterdam",
    status: "in_transit",
    vehicle: "scooter",
    coverage_area: "amsterdam-east"
  },
  %{
    name: "Sophie Delivery",
    email: "courier.sophie@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-1004",
    default_address: "Van Baerlestraat 55, 1071 AR Amsterdam",
    status: "active",
    vehicle: "bicycle",
    coverage_area: "amsterdam-south"
  },
  %{
    name: "Fast Piet",
    email: "courier.piet@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-1005",
    default_address: "Noord District 25, 1022 AC Amsterdam",
    status: "offline",
    vehicle: "car",
    coverage_area: "amsterdam-noord"
  },

  # Utrecht couriers
  %{
    name: "Utrecht Rider",
    email: "courier.utrecht@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-2001",
    default_address: "Oudegracht 200, 3511 NZ Utrecht",
    status: "active",
    vehicle: "bicycle",
    coverage_area: "utrecht-center"
  },
  %{
    name: "Snelle Jan",
    email: "courier.jan.utrecht@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-2002",
    default_address: "Nobelstraat 200, 3512 EP Utrecht",
    status: "in_transit",
    vehicle: "e-bike",
    coverage_area: "utrecht-south"
  },

  # Het Gooi couriers
  %{
    name: "Gooi Delivery",
    email: "courier.gooi@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-3001",
    default_address: "Kerkstraat 88, 1251 RT Laren",
    status: "active",
    vehicle: "car",
    coverage_area: "het-gooi"
  },

  # International couriers
  %{
    name: "Berlin Biker",
    email: "courier.berlin@eatfair.de",
    password: "password123456",
    role: "courier",
    phone_number: "+49-30-1111-4001",
    default_address: "Friedrichshain 100, 10249 Berlin",
    status: "active",
    vehicle: "bicycle",
    coverage_area: "berlin-center"
  },
  %{
    name: "London Courier",
    email: "courier.london@eatfair.co.uk",
    password: "password123456",
    role: "courier",
    phone_number: "+44-20-1111-4002",
    default_address: "Camden Market 15, NW1 8AH London",
    status: "offline",
    vehicle: "motorcycle",
    coverage_area: "london-north"
  },

  # Edge case couriers
  %{
    name: "Boundary Courier",
    email: "courier.boundary@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-5001",
    default_address: "Edge of City 1, 1099 XX Amsterdam",
    status: "active",
    vehicle: "bicycle",
    coverage_area: "boundary-testing"
  },
  %{
    name: "Slow Walker",
    email: "courier.slow@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-1111-5002",
    default_address: "Slow Street 1, 1010 AA Amsterdam",
    status: "active",
    vehicle: "on_foot",
    coverage_area: "very-local"
  },

  # Test courier
  %{
    name: "Test Courier",
    email: "testcourier@eatfair.nl",
    password: "password123456",
    role: "courier",
    phone_number: "+31-6-9999-0001",
    default_address: "Central Testing 1, 1000 TE Amsterdam",
    status: "active",
    vehicle: "e-bike",
    coverage_area: "test-area"
  }
]

couriers =
  Enum.map(courier_data, fn attrs ->
    # Remove custom fields not in User schema
    user_attrs = attrs |> Map.drop([:status, :vehicle, :coverage_area])

    %User{}
    |> User.registration_changeset(user_attrs)
    |> Repo.insert!()
    |> User.confirm_changeset()
    |> Repo.update!()
  end)

IO.puts("✅ Created #{length(couriers)} courier users")

# Create Address records for couriers  
IO.puts("📍 Creating courier addresses...")

couriers_with_data = Enum.zip(couriers, courier_data)

Enum.each(couriers_with_data, fn {user, courier_info} ->
  if user.default_address && String.trim(user.default_address) != "" do
    {street, city, postal_code, country} = parse_address.(user.default_address)

    case Eatfair.Accounts.create_address(%{
           "name" => "Work Base",
           "street_address" => street,
           "city" => city,
           "postal_code" => postal_code,
           "country" => country,
           "is_default" => true,
           "user_id" => user.id
         }) do
      {:ok, _addr} ->
        :ok

      {:error, changeset} ->
        IO.puts(
          "⚠️ Failed to create address for courier #{user.email}: #{inspect(changeset.errors)}"
        )
    end
  end
end)

IO.puts("✅ Created addresses for all couriers")

# ============================================================================
# 6. GENERATE EXTENSIVE ORDER HISTORY WITH ALL STATUS TYPES
# ============================================================================

IO.puts("📝 Generating comprehensive order history...")

# Create realistic order patterns spanning several months
if Mix.env() == :dev do
  # Helper to create orders with realistic patterns
  create_order_batch = fn customer, customer_data, restaurant, days_ago ->
    # Determine order frequency based on loyalty level
    orders_this_month =
      case customer_data[:loyalty_level] do
        # 3-10 orders
        "platinum" -> rem(customer.id * days_ago, 8) + 3
        # 2-6 orders
        "gold" -> rem(customer.id * days_ago, 5) + 2
        # 1-3 orders
        "silver" -> rem(customer.id * days_ago, 3) + 1
        # 0-1 orders
        "bronze" -> rem(customer.id * days_ago, 2)
        # Occasional orders
        _ -> if rem(customer.id * days_ago, 4) == 0, do: 1, else: 0
      end

    # Create orders for this customer/restaurant combination
    1..orders_this_month
    |> Enum.map(fn order_num ->
      # Vary order timing within the day
      # 6 AM to midnight
      hours_offset = rem(customer.id * order_num, 18) + 6
      minutes_offset = rem(customer.id * order_num * 17, 60)

      order_time =
        DateTime.utc_now()
        # Days ago
        |> DateTime.add(-days_ago * 24 * 60 * 60, :second)
        # Hour of day
        |> DateTime.add(-hours_offset * 60 * 60, :second)
        # Minute
        |> DateTime.add(-minutes_offset * 60, :second)
        |> DateTime.to_naive()
        |> NaiveDateTime.truncate(:second)

      # Determine order status based on how recent it is
      status =
        case days_ago do
          # Today's orders
          0 -> ["confirmed", "preparing"] |> Enum.at(rem(order_num, 2))
          # Yesterday
          1 -> ["ready", "out_for_delivery", "delivered"] |> Enum.at(rem(order_num, 3))
          # This week
          2..7 -> "delivered"
          # This month - some cancelled
          8..30 -> if rem(order_num, 20) == 0, do: "cancelled", else: "delivered"
          # Older orders - all delivered
          _ -> "delivered"
        end

      # Get restaurant's menu items
      restaurant_with_menus =
        Restaurants.get_restaurant!(restaurant.id) |> Repo.preload(menus: :meals)

      all_meals =
        restaurant_with_menus.menus
        |> Enum.flat_map(fn menu -> menu.meals end)
        |> Enum.filter(fn meal -> meal.is_available end)

      if length(all_meals) > 0 do
        # Select 1-4 random meals for the order
        num_items = rem(customer.id * order_num, 4) + 1
        selected_meals = all_meals |> Enum.take_random(min(num_items, length(all_meals)))

        # Calculate total price
        item_total =
          selected_meals
          |> Enum.reduce(Decimal.new("0"), fn meal, acc ->
            # 1-3 quantity
            quantity = rem(customer.id * String.to_integer(to_string(meal.id)), 3) + 1
            Decimal.add(acc, Decimal.mult(meal.price, quantity))
          end)

        # Add delivery fee if order is small
        delivery_fee =
          if Decimal.cmp(item_total, restaurant.min_order_value) == :lt do
            Decimal.new("3.50")
          else
            Decimal.new("0.00")
          end

        total_price = Decimal.add(item_total, delivery_fee)

        # Only create order if it meets minimum
        if Decimal.cmp(total_price, restaurant.min_order_value) != :lt do
          # Create the order with proper timestamps
          order_attrs = %{
            customer_id: customer.id,
            restaurant_id: restaurant.id,
            status: status,
            total_price: total_price,
            delivery_address: customer.default_address || "Test Address 1, 1000 AA Amsterdam",
            phone_number: customer.phone_number || "+31-20-555-0000",
            delivery_notes:
              ["Ring the bell", "Leave at door", "Call when arrived", "Buzzer code: 1234", ""]
              |> Enum.at(rem(order_num, 5)),
            inserted_at: order_time,
            updated_at: order_time
          }

          # Add status timestamps based on order status
          order_attrs =
            case status do
              "confirmed" ->
                order_attrs |> Map.put(:confirmed_at, order_time)

              "preparing" ->
                confirmed_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -5 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                prep_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -2 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                order_attrs
                |> Map.put(:confirmed_at, confirmed_time)
                |> Map.put(:preparing_at, prep_time)

              "ready" ->
                confirmed_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -25 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                prep_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -20 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                ready_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -5 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                order_attrs
                |> Map.put(:confirmed_at, confirmed_time)
                |> Map.put(:preparing_at, prep_time)
                |> Map.put(:ready_at, ready_time)

              "out_for_delivery" ->
                confirmed_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -35 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                prep_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -30 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                ready_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -15 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                delivery_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -5 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                courier = couriers |> Enum.random()

                order_attrs
                |> Map.put(:confirmed_at, confirmed_time)
                |> Map.put(:preparing_at, prep_time)
                |> Map.put(:ready_at, ready_time)
                |> Map.put(:out_for_delivery_at, delivery_time)
                |> Map.put(:courier_id, courier.id)
                |> Map.put(:courier_assigned_at, ready_time)

              "delivered" ->
                confirmed_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -60 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                prep_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -50 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                ready_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -25 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                delivery_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -20 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                courier = couriers |> Enum.random()

                order_attrs
                |> Map.put(:confirmed_at, confirmed_time)
                |> Map.put(:preparing_at, prep_time)
                |> Map.put(:ready_at, ready_time)
                |> Map.put(:out_for_delivery_at, delivery_time)
                |> Map.put(:delivered_at, order_time)
                |> Map.put(:courier_id, courier.id)
                |> Map.put(:courier_assigned_at, ready_time)

              "cancelled" ->
                confirmed_time =
                  DateTime.add(DateTime.from_naive!(order_time, "Etc/UTC"), -10 * 60, :second)
                  |> DateTime.to_naive()
                  |> NaiveDateTime.truncate(:second)

                order_attrs
                |> Map.put(:confirmed_at, confirmed_time)
                |> Map.put(:cancelled_at, order_time)

              _ ->
                order_attrs |> Map.put(:confirmed_at, order_time)
            end

          # Create order using raw SQL to preserve timestamps
          {:ok, order} =
            %Order{}
            |> Order.changeset(order_attrs)
            |> Repo.insert()

          # Create order items
          order_items =
            selected_meals
            |> Enum.map(fn meal ->
              quantity = rem(customer.id * String.to_integer(to_string(meal.id)), 3) + 1

              %{
                order_id: order.id,
                meal_id: meal.id,
                quantity: quantity,
                inserted_at: NaiveDateTime.truncate(order_time, :second),
                updated_at: NaiveDateTime.truncate(order_time, :second)
              }
            end)

          if length(order_items) > 0 do
            Repo.insert_all("order_items", order_items)
          end

          # Create payment
          payment_status =
            case status do
              "cancelled" -> "failed"
              _ -> "completed"
            end

          {:ok, _payment} =
            Repo.insert(%Payment{
              order_id: order.id,
              amount: total_price,
              status: payment_status,
              inserted_at: NaiveDateTime.truncate(order_time, :second),
              updated_at: NaiveDateTime.truncate(order_time, :second)
            })

          order
        end
      end
    end)
    # Remove nils
    |> Enum.filter(& &1)
  end

  # Generate orders for the past 3 months
  # 90 days
  total_orders_created =
    0..90
    |> Enum.map(fn days_ago ->
      # Create orders for active customers on this day
      active_customers = customers |> Enum.zip(all_customers_data)

      daily_orders =
        active_customers
        |> Enum.flat_map(fn {customer, customer_data} ->
          # Skip some customers on some days
          if rem(customer.id + days_ago, 4) == 0 do
            # Select restaurants this customer might order from (prefer nearby)
            available_restaurants =
              case String.contains?(customer.default_address || "", ["Amsterdam", "1012", "1016"]) do
                true ->
                  restaurants |> Enum.filter(fn r -> String.contains?(r.city, "Amsterdam") end)

                _ ->
                  case String.contains?(customer.default_address || "", [
                         "Utrecht",
                         "3511",
                         "3512"
                       ]) do
                    true ->
                      restaurants |> Enum.filter(fn r -> String.contains?(r.city, "Utrecht") end)

                    # International customers can order from anywhere
                    _ ->
                      restaurants
                  end
              end

            if length(available_restaurants) > 0 do
              # Customer orders from 1-2 restaurants this day
              selected_restaurants =
                available_restaurants |> Enum.take_random(min(2, length(available_restaurants)))

              selected_restaurants
              |> Enum.flat_map(fn restaurant ->
                create_order_batch.(customer, customer_data, restaurant, days_ago)
              end)
            else
              []
            end
          else
            []
          end
        end)

      daily_orders
    end)
    |> List.flatten()
    |> Enum.filter(& &1)
    |> length()

  IO.puts("✅ Created #{total_orders_created} orders with realistic patterns across 90 days")
end

# ============================================================================
# 7. CREATE COMPREHENSIVE REVIEW AND RATING SYSTEM
# ============================================================================

IO.puts("⭐ Creating comprehensive reviews and ratings...")

if Mix.env() == :dev do
  # Get all delivered orders for review creation
  delivered_orders =
    from(o in Order, where: o.status == "delivered")
    |> Repo.all()
    |> Repo.preload([:customer, :restaurant])

  IO.puts("Found #{length(delivered_orders)} delivered orders for potential reviews")

  # Create reviews for a portion of delivered orders (realistic review rate ~20-30%)
  reviews_created =
    delivered_orders
    |> Enum.filter(fn order ->
      # Only some orders get reviews (based on customer behavior)
      customer_factor = rem(order.customer_id, 10)

      case customer_factor do
        # 30% very active reviewers
        0..2 -> true
        # 20% occasional reviewers  
        3..5 -> rem(order.id, 3) == 0
        # 10% rare reviewers
        _ -> rem(order.id, 10) == 0
      end
    end)
    |> Enum.map(fn order ->
      # Generate realistic review content
      rating =
        case rem(order.customer_id + order.restaurant_id, 20) do
          # 5% - terrible
          0 -> 1
          # 10% - poor
          1..2 -> 2
          # 15% - okay
          3..5 -> 3
          # 35% - good
          6..12 -> 4
          # 35% - excellent
          _ -> 5
        end

      # Generate review comments based on rating
      comment =
        case rating do
          1 ->
            [
              "Food arrived cold and took way too long. Very disappointed.",
              "Wrong order, poor quality, will not order again.",
              "Terrible experience. Food was inedible and delivery was a mess.",
              "Complete waste of money. Cold, tasteless food."
            ]
            |> Enum.at(rem(order.id, 4))

          2 ->
            [
              "Food was okay but delivery took much longer than expected.",
              "Not great quality for the price. Expected better.",
              "Average food, slow delivery. Room for improvement.",
              "Below expectations. Food was lukewarm when it arrived."
            ]
            |> Enum.at(rem(order.id, 4))

          3 ->
            [
              "Decent food, nothing special but satisfied my hunger.",
              "Average quality, fair price. Would consider ordering again.",
              "Food was fine, delivery on time. Standard experience.",
              "Okay meal, met basic expectations."
            ]
            |> Enum.at(rem(order.id, 4))

          4 ->
            [
              "Great food and fast delivery! Really enjoyed my meal.",
              "Very good quality ingredients and tasty dishes. Will order again.",
              "Excellent service and delicious food. Highly recommend!",
              "Really impressed with the quality. Fresh and flavorful.",
              "Fast delivery and hot food. Great experience overall.",
              "Delicious meal, well prepared and packaged nicely."
            ]
            |> Enum.at(rem(order.id, 6))

          5 ->
            [
              "Absolutely fantastic! Best meal I've had delivered. Perfect!",
              "Outstanding quality and lightning-fast delivery. 5 stars!",
              "Incredible flavors and presentation. This restaurant is amazing!",
              "Perfect meal, arrived hot and fresh. Couldn't be happier!",
              "Exceptional food quality and service. My new favorite restaurant!",
              "Wow! Exceeded all expectations. Will definitely order again soon!",
              "Restaurant quality food delivered to my door. Simply perfect.",
              "Amazing attention to detail. Every bite was delicious!"
            ]
            |> Enum.at(rem(order.id, 8))
        end

      # Add specific details based on restaurant type for realism
      detailed_comment =
        case String.downcase(order.restaurant.name) do
          name ->
            cond do
              String.contains?(name, "italian") ->
                case rating do
                  4..5 ->
                    comment <> " The pasta was cooked perfectly and the sauce was authentic."

                  1..2 ->
                    comment <> " The pizza was soggy and pasta was overcooked."

                  _ ->
                    comment
                end

              String.contains?(name, "sushi") ->
                case rating do
                  4..5 ->
                    comment <> " Fish was incredibly fresh and sushi was beautifully prepared."

                  1..2 ->
                    comment <> " Sushi was not fresh and rice was mushy."

                  _ ->
                    comment
                end

              String.contains?(name, "chinese") ->
                case rating do
                  4..5 -> comment <> " Authentic flavors and generous portions."
                  1..2 -> comment <> " Food was greasy and lacked flavor."
                  _ -> comment
                end

              true ->
                comment
            end
        end

      # Some reviews are shorter (just rating, minimal comment)
      final_comment =
        case rem(order.id, 8) do
          0 -> "Good!"
          1 -> "Recommended"
          2 -> "Not bad"
          # No comment, just rating
          3 -> nil
          _ -> detailed_comment
        end

      # Create the review
      review_attrs = %{
        rating: rating,
        comment: final_comment,
        user_id: order.customer_id,
        restaurant_id: order.restaurant_id,
        order_id: order.id
      }

      case Reviews.create_review(review_attrs) do
        {:ok, review} ->
          review

        {:error, changeset} ->
          IO.puts("⚠️ Failed to create review: #{inspect(changeset.errors)}")
          nil
      end
    end)
    |> Enum.filter(& &1)
    |> length()

  IO.puts("✅ Created #{reviews_created} diverse reviews from delivered orders")

  # Update restaurant ratings based on actual reviews
  IO.puts("🗘️ Updating restaurant ratings based on reviews...")

  restaurants_updated =
    restaurants
    |> Enum.map(fn restaurant ->
      # Get all reviews for this restaurant
      restaurant_reviews =
        from(r in Eatfair.Reviews.Review, where: r.restaurant_id == ^restaurant.id)
        |> Repo.all()

      if length(restaurant_reviews) > 0 do
        # Calculate average rating
        total_rating =
          restaurant_reviews |> Enum.reduce(0, fn review, acc -> acc + review.rating end)

        avg_rating = total_rating / length(restaurant_reviews)

        # Update restaurant with calculated rating
        restaurant
        |> Ecto.Changeset.change(rating: Decimal.from_float(avg_rating))
        |> Repo.update!()
      else
        restaurant
      end
    end)
    |> length()

  IO.puts("✅ Updated #{restaurants_updated} restaurants with calculated ratings")
end

# ============================================================================
# 8. IMPLEMENT REALISTIC DELIVERY PATTERNS AND LOGISTICS
# ============================================================================

IO.puts("🚚 Setting up realistic delivery logistics...")

# Update some orders to have current delivery status for dashboard testing
if Mix.env() == :dev do
  # Get recent orders that should be in active delivery states
  recent_orders =
    from(o in Order,
      where:
        o.inserted_at > ago(24, "hour") and o.status in ["preparing", "ready", "out_for_delivery"]
    )
    |> Repo.all()

  if length(recent_orders) > 0 do
    # Assign couriers to out_for_delivery orders
    out_for_delivery_orders =
      recent_orders |> Enum.filter(fn o -> o.status == "out_for_delivery" end)

    Enum.each(out_for_delivery_orders, fn order ->
      # Find a suitable courier (active and in same region)
      suitable_courier =
        couriers
        |> Enum.find(fn courier ->
          courier.default_address && String.contains?(courier.default_address, "Amsterdam")
        end)

      if suitable_courier do
        order
        |> Ecto.Changeset.change(
          courier_id: suitable_courier.id,
          courier_assigned_at:
            DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)
        )
        |> Repo.update!()
      end
    end)

    IO.puts(
      "✅ Updated delivery logistics for #{length(out_for_delivery_orders)} active delivery orders"
    )
  end
end

# ============================================================================
# 9. CREATE EDGE CASES AND FINALIZE TEST DATA
# ============================================================================

IO.puts("⚠️ Adding edge cases and finalizing data...")

# Already implemented many edge cases throughout:
# - Mystery Kitchen with minimal menu
# - Boundary testing restaurants and users
# - International addresses and users
# - Incomplete user profiles
# - Various order statuses and edge cases
# - Couriers with different vehicles and statuses
# - Restaurants with unusual delivery radiuses and pricing

# Final data summary and statistics
IO.puts("
✨ ENHANCED SEED DATA CREATION COMPLETE! ✨")

# Generate comprehensive statistics
cuisine_count = Repo.aggregate(Cuisine, :count, :id)
restaurant_count = Repo.aggregate(Restaurant, :count, :id)
customer_count = from(u in User, where: u.role == "customer") |> Repo.aggregate(:count, :id)
owner_count = from(u in User, where: u.role == "restaurant_owner") |> Repo.aggregate(:count, :id)
courier_count = from(u in User, where: u.role == "courier") |> Repo.aggregate(:count, :id)
order_count = Repo.aggregate(Order, :count, :id)
review_count = Repo.aggregate(Eatfair.Reviews.Review, :count, :id)
menu_count = Repo.aggregate(Menu, :count, :id)
meal_count = Repo.aggregate(Meal, :count, :id)
address_count = Repo.aggregate(Eatfair.Accounts.Address, :count, :id)

# Order statistics by status
order_stats =
  from(o in Order, group_by: o.status, select: {o.status, count(o.id)})
  |> Repo.all()
  |> Enum.into(%{})

# Restaurant distribution by city
restaurant_distribution =
  from(r in Restaurant, group_by: r.city, select: {r.city, count(r.id)})
  |> Repo.all()
  |> Enum.into(%{})

# Customer loyalty distribution
customers_with_order_counts =
  from(c in User,
    left_join: o in Order,
    on: c.id == o.customer_id,
    where: c.role == "customer",
    group_by: c.id,
    select: {c.id, c.email, count(o.id)}
  )
  |> Repo.all()

very_active_customers =
  customers_with_order_counts |> Enum.filter(fn {_, _, count} -> count >= 15 end) |> length()

active_customers =
  customers_with_order_counts
  |> Enum.filter(fn {_, _, count} -> count >= 5 and count < 15 end)
  |> length()

occasional_customers =
  customers_with_order_counts
  |> Enum.filter(fn {_, _, count} -> count > 0 and count < 5 end)
  |> length()

inactive_customers =
  customers_with_order_counts |> Enum.filter(fn {_, _, count} -> count == 0 end) |> length()

# Average rating across all restaurants
avg_platform_rating =
  from(r in Restaurant, where: not is_nil(r.rating), select: avg(r.rating))
  |> Repo.one()
  |> case do
    nil -> "N/A"
    rating -> Float.round(Decimal.to_float(rating), 2)
  end

IO.puts("✨ ======================================================")
IO.puts("✨              COMPREHENSIVE DATA SUMMARY             ✨")
IO.puts("✨ ======================================================")

IO.puts("🌍 **GEOGRAPHIC DISTRIBUTION**")

Enum.each(restaurant_distribution, fn {city, count} ->
  IO.puts("   • #{city}: #{count} restaurants")
end)

IO.puts("\n📈 **PLATFORM STATISTICS**")
IO.puts("   • Cuisines & Categories: #{cuisine_count}")
IO.puts("   • Restaurants: #{restaurant_count}")
IO.puts("   • Menu Sections: #{menu_count}")
IO.puts("   • Menu Items: #{meal_count}")
IO.puts("   • Average Platform Rating: #{avg_platform_rating}/5.0")

IO.puts("\n👥 **USER DISTRIBUTION**")
IO.puts("   • Customers: #{customer_count}")
IO.puts("   • Restaurant Owners: #{owner_count}")
IO.puts("   • Couriers: #{courier_count}")
IO.puts("   • Total Addresses: #{address_count}")

IO.puts("\n👥 **CUSTOMER ACTIVITY LEVELS**")
IO.puts("   • Very Active (15+ orders): #{very_active_customers}")
IO.puts("   • Active (5-14 orders): #{active_customers}")
IO.puts("   • Occasional (1-4 orders): #{occasional_customers}")
IO.puts("   • Inactive (0 orders): #{inactive_customers}")

IO.puts("\n📝 **ORDER & DELIVERY STATISTICS**")
IO.puts("   • Total Orders: #{order_count}")

Enum.each(order_stats, fn {status, count} ->
  percentage = Float.round(count / order_count * 100, 1)

  IO.puts(
    "   • #{String.capitalize(String.replace(status, "_", " "))}: #{count} (#{percentage}%)"
  )
end)

IO.puts("\n⭐ **REVIEWS & RATINGS**")
IO.puts("   • Total Reviews: #{review_count}")

if review_count > 0 do
  review_rate = Float.round(review_count / order_count * 100, 1)
  IO.puts("   • Review Rate: #{review_rate}% of orders")

  # Rating distribution
  rating_distribution =
    from(r in Eatfair.Reviews.Review, group_by: r.rating, select: {r.rating, count(r.id)})
    |> Repo.all()
    |> Enum.into(%{})

  IO.puts("   • Rating Distribution:")

  1..5
  |> Enum.each(fn star ->
    count = Map.get(rating_distribution, star, 0)

    if count > 0 do
      percentage = Float.round(count / review_count * 100, 1)
      IO.puts("     #{star} ★: #{count} (#{percentage}%)")
    end
  end)
end

IO.puts("\n🎆 **SPECIAL FEATURES IMPLEMENTED**")
IO.puts("   • ✅ Multi-region coverage (Netherlands, Germany, France, UK, Canada, US)")
IO.puts("   • ✅ Realistic customer loyalty patterns and behaviors")
IO.puts("   • ✅ Comprehensive order history spanning 3 months")
IO.puts("   • ✅ Diverse menu structures (minimal to extensive)")
IO.puts("   • ✅ Edge cases: boundary testing, incomplete data, unusual scenarios")
IO.puts("   • ✅ Active courier network with different vehicle types")
IO.puts("   • ✅ Realistic delivery logistics and real-time order tracking")
IO.puts("   • ✅ International address formats and geographic diversity")
IO.puts("   • ✅ Varied dietary preferences and customer behaviors")
IO.puts("   • ✅ Multiple addresses per user scenarios")
IO.puts("   • ✅ Restaurant dashboard populated with diverse order statuses")

IO.puts("\n🚀 **READY FOR COMPREHENSIVE TESTING**")
IO.puts("   • Login as any user to explore their unique experience")
IO.puts("   • Test restaurant discovery with heavy Amsterdam concentration")
IO.puts("   • Explore diverse restaurants, menus, and cuisines")
IO.puts("   • View restaurant dashboards with realistic order volumes")
IO.puts("   • Test delivery boundaries and international scenarios")
IO.puts("   • Experience various user loyalty levels and behaviors")
IO.puts("   • Review system with authentic customer feedback patterns")

IO.puts("\n🌟 **KEY TEST ACCOUNTS**")
IO.puts("👥 **CUSTOMERS:**")
IO.puts("   • frequent@eatfair.nl - Very active customer (Gold level)")
IO.puts("   • test@eatfair.nl - Test customer (50+ orders)")
IO.puts("   • vegan@eatfair.nl - Vegan customer with dietary restrictions")
IO.puts("   • multi@eatfair.nl - User with multiple addresses")
IO.puts("   • boundary@eatfair.nl - Edge case delivery testing")

IO.puts("\n🏒 **RESTAURANT OWNERS:**")
IO.puts("   • owner0@bellaitaliaamsterdam.nl - Bella Italia Central")
IO.puts("   • owner1@goldenlotuscentral.nl - Golden Lotus (Chinese)")
IO.puts("   • owner2@jordaanbistro.nl - Jordaan Bistro (French)")

IO.puts("\n🚚 **COURIERS:**")
IO.puts("   • courier.max@eatfair.nl - Amsterdam center courier (Active)")
IO.puts("   • courier.ahmed@eatfair.nl - Currently in transit")
IO.puts("   • testcourier@eatfair.nl - Test courier")

IO.puts("\n✨ ALL PASSWORDS: password123456")

IO.puts("\n🎉 **START TESTING**: mix phx.server")
IO.puts("✨ ====================================================== ✨\n")
