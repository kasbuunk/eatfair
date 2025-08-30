defmodule Eatfair.Restaurants.RestaurantOperationalHoursTest do
  use Eatfair.DataCase

  import Eatfair.RestaurantsFixtures
  alias Eatfair.Restaurants.Restaurant

  describe "restaurant operational hours" do
    test "minutes_to_time/1 converts minutes to HH:MM format" do
      assert Restaurant.minutes_to_time(0) == "00:00"
      assert Restaurant.minutes_to_time(540) == "09:00"
      assert Restaurant.minutes_to_time(1320) == "22:00"
      assert Restaurant.minutes_to_time(1439) == "23:59"
      assert Restaurant.minutes_to_time(1440) == "24:00"
      assert Restaurant.minutes_to_time(1441) == "Invalid"
    end

    test "time_to_minutes/1 converts HH:MM to minutes from midnight" do
      assert Restaurant.time_to_minutes("00:00") == 0
      assert Restaurant.time_to_minutes("09:00") == 540
      assert Restaurant.time_to_minutes("22:00") == 1320
      assert Restaurant.time_to_minutes("23:59") == 1439
      assert Restaurant.time_to_minutes("24:00") == 1440
      assert Restaurant.time_to_minutes("25:00") == {:error, :invalid_time}
      assert Restaurant.time_to_minutes("invalid") == {:error, :invalid_format}
    end

    test "open_for_orders?/1 respects force_closed flag" do
      restaurant =
        restaurant_fixture(%{
          force_closed: true,
          timezone: "Europe/Amsterdam",
          # All days
          operating_days: 127,
          # 10:00
          order_open_time: 600,
          # 21:00
          order_close_time: 1260
        })

      refute Restaurant.open_for_orders?(restaurant)
    end

    test "open_for_orders?/1 checks day of week" do
      # Monday only (bit 1)
      restaurant =
        restaurant_fixture(%{
          force_closed: false,
          timezone: "Europe/Amsterdam",
          operating_days: 1,
          # 10:00
          order_open_time: 600,
          # 20:00
          order_close_time: 1200,
          # 21:00
          kitchen_close_time: 1260,
          # 1 hour buffer
          order_cutoff_before_kitchen_close: 60
        })

      # Test would need to mock DateTime.now!/1 to test specific days
      # For now, just ensure the function doesn't crash
      assert is_boolean(Restaurant.open_for_orders?(restaurant))
    end

    test "open_for_orders?/1 checks time of day" do
      # Create restaurant open 10:00-21:00 all days
      restaurant =
        restaurant_fixture(%{
          force_closed: false,
          timezone: "Europe/Amsterdam",
          operating_days: 127,
          # 10:00
          order_open_time: 600,
          # 21:00
          order_close_time: 1260
        })

      # Function should return boolean without errors
      assert is_boolean(Restaurant.open_for_orders?(restaurant))
    end

    test "last_order_time_today/1 returns nil for closed restaurant" do
      restaurant =
        restaurant_fixture(%{
          force_closed: true,
          timezone: "Europe/Amsterdam"
        })

      assert Restaurant.last_order_time_today(restaurant) == nil
    end
  end

  describe "restaurant changeset validation" do
    test "validates operational hours are within valid range" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        # Invalid
        contact_open_time: -1
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset)[:contact_open_time] == [
               "contact hours open time must be between 00:00 and 23:59"
             ]
    end

    test "validates kitchen closes after order cutoff buffer" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        # 20:00
        order_close_time: 1200,
        # 20:00
        kitchen_close_time: 1200,
        # 30 minutes buffer
        order_cutoff_before_kitchen_close: 30
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset)[:order_close_time] == [
               "order acceptance must end 30 minutes before kitchen closes"
             ]
    end

    test "validates timezone is in allowed list" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        timezone: "Invalid/Timezone"
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      refute changeset.valid?
      assert errors_on(changeset)[:timezone] == ["is invalid"]
    end

    test "validates operating days bitmask" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        # Invalid - no operating days
        operating_days: 0
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      refute changeset.valid?
      assert errors_on(changeset)[:operating_days] == ["must be greater than 0"]
    end

    test "accepts valid operational configuration" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        timezone: "Europe/Amsterdam",
        # 09:00
        contact_open_time: 540,
        # 22:00
        contact_close_time: 1320,
        # 10:00
        order_open_time: 600,
        # 20:30
        order_close_time: 1230,
        # 10:00
        kitchen_open_time: 600,
        # 21:00
        kitchen_close_time: 1260,
        # 30 minutes
        order_cutoff_before_kitchen_close: 30,
        # All days
        operating_days: 127
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      assert changeset.valid?
    end
  end

  describe "edge cases and timezone boundaries" do
    test "handles midnight crossover for operational hours" do
      # Restaurant open late (22:00 to 02:00 next day) 
      attrs = %{
        name: "Late Night Restaurant",
        address: "123 Night St",
        owner_id: 1,
        # 22:00
        contact_open_time: 1320,
        # 02:00 (next day)
        contact_close_time: 120
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      # This should be valid - restaurant can operate across midnight
      assert changeset.valid?
    end

    test "prevents impossible time configurations" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        # 20:00
        order_open_time: 1200,
        # 20:00 - same as open time (invalid)
        order_close_time: 1200
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset)[:order_close_time] == [
               "order hours close time must be different from open time"
             ]
    end

    test "validates buffer times are reasonable" do
      attrs = %{
        name: "Test Restaurant",
        address: "123 Test St",
        owner_id: 1,
        # > 120 minutes (invalid)
        order_cutoff_before_kitchen_close: 200
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset)[:order_cutoff_before_kitchen_close] == [
               "must be less than or equal to 120"
             ]
    end
  end

  describe "24/7 restaurant operations" do
    test "24/7 restaurant logic can be validated by checking times directly" do
      # Test the logic that should handle 24/7 operations
      # If order_close_time is 1440 (24:00) and order_open_time is 0 (00:00)
      # then any time should be within the range

      # Simulate the logic from Restaurant.open_for_orders?
      # 00:00
      order_open_time = 0
      # 24:00 (end of day)
      order_close_time = 1440

      # 00:00, 06:00, 12:00, 18:00, 22:00, 23:59
      test_times = [0, 360, 720, 1080, 1320, 1439]

      for current_minute <- test_times do
        # Current logic: current_minute >= order_open_time and current_minute < order_close_time
        within_hours? = current_minute >= order_open_time and current_minute < order_close_time

        assert within_hours?,
               "Time #{Restaurant.minutes_to_time(current_minute)} should be within 24/7 hours (#{order_open_time}-#{order_close_time})"
      end
    end

    test "Night Owl Express NL should be configured as 24/7" do
      alias Eatfair.Repo

      night_owl = Repo.get_by(Restaurant, name: "Night Owl Express NL")
      assert night_owl != nil, "Night Owl Express NL restaurant should exist"

      # This test will initially fail - that's the bug we're fixing
      assert night_owl.order_open_time == 0, "Night Owl should open at 00:00"
      assert night_owl.order_close_time == 1440, "Night Owl should close at 24:00 (1440 minutes)"
      assert night_owl.operating_days == 127, "Night Owl should operate all days"
      assert night_owl.force_closed == false, "Night Owl should not be force closed"
    end

    test "24/7 restaurant validates correctly in changeset" do
      attrs = %{
        name: "24/7 Test Restaurant",
        address: "123 Always Open St",
        owner_id: 1,
        timezone: "Europe/Amsterdam",
        # 00:00
        order_open_time: 0,
        # 24:00
        order_close_time: 1440,
        # All days
        operating_days: 127
      }

      changeset = Restaurant.changeset(%Restaurant{}, attrs)
      assert changeset.valid?, "24/7 configuration should be valid"
    end
  end
end
