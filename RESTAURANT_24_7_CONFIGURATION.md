# Restaurant 24/7 Configuration Guide

This document explains how to configure restaurants for 24/7 (always open) operation in the Eatfair system.

## 24/7 Configuration Rules

To configure a restaurant as truly 24/7 (always open for orders), you must set the following operational hours:

```elixir
%Restaurant{
  order_open_time: 0,        # 00:00 (midnight)
  order_close_time: 1440,    # 24:00 (next midnight) - this is the key!
  kitchen_open_time: 0,      # 00:00 (optional, will be auto-set)
  kitchen_close_time: 1440,  # 24:00 (will be auto-adjusted)
  last_delivery_time: 1440,  # 24:00 (will be auto-adjusted)
  operating_days: 127,       # All days (binary: 1111111)
  force_closed: false        # Must not be force closed
}
```

### Key Points

1. **Critical Rule**: `order_close_time: 1440` is the explicit indicator for 24/7 operation
2. **Auto-adjustment**: When `order_close_time == 1440`, the validation automatically adjusts:
   - `kitchen_close_time` to 1440 if it's less than 1440
   - `last_delivery_time` to 1440 
3. **Validation**: The system allows the edge case where `order_open_time == 0` and `order_close_time == 1440`
4. **Runtime Logic**: The `open_for_orders?/1` function returns `true` immediately for 24/7 configured restaurants

## Implementation Details

### Database Schema
All time values are stored as integers representing minutes from midnight:
- `0` = 00:00 (midnight)
- `1440` = 24:00 (next midnight) = 24 hours * 60 minutes

### Validation Logic
The `validate_operational_logic/1` function includes special handling for 24/7:

```elixir
# 24/7 special case: order_open_time == 0 and order_close_time == 1440
if attrs.order_open_time == 0 and attrs.order_close_time == 1440 do
  # Auto-adjust kitchen and delivery times for 24/7 operation
  attrs = 
    attrs
    |> update_if_needed(:kitchen_close_time, fn time -> if time < 1440, do: 1440, else: time end)
    |> update_if_needed(:last_delivery_time, fn time -> if time < 1440, do: 1440, else: time end)
  
  {:ok, attrs}
else
  # Regular validation for non-24/7 restaurants
  # ... standard validation logic
end
```

### Runtime Logic
The `open_for_orders?/1` function includes fast-path for 24/7:

```elixir
def open_for_orders?(%Restaurant{order_open_time: 0, order_close_time: 1440} = _restaurant) do
  true  # Always open for 24/7 configured restaurants
end

def open_for_orders?(restaurant) do
  # Regular time-based logic for non-24/7 restaurants
  # ... standard logic
end
```

## Example: Night Owl Express NL

```elixir
# In seeds.exs or migration
%{
  name: "Night Owl Express NL",
  # ... other fields ...
  order_open_time: 0,      # 00:00 
  order_close_time: 1440,  # 24:00 - indicates 24/7
  kitchen_open_time: 0,    # 00:00
  kitchen_close_time: 1440, # 24:00 (auto-adjusted)
  last_delivery_time: 1440, # 24:00 (auto-adjusted)
  operating_days: 127,     # All days of week
  force_closed: false
}
```

## Testing 24/7 Restaurants

### Unit Tests
```elixir
test "24/7 restaurant should be always open" do
  restaurant = build(:restaurant, 
    order_open_time: 0, 
    order_close_time: 1440
  )
  
  # Should be open at any time
  assert Restaurant.open_for_orders?(restaurant)
end

test "24/7 changeset validation should succeed" do
  attrs = %{
    order_open_time: 0,
    order_close_time: 1440,
    kitchen_open_time: 0,
    kitchen_close_time: 1320  # Will be auto-adjusted to 1440
  }
  
  changeset = Restaurant.changeset(%Restaurant{}, attrs)
  assert changeset.valid?
  assert changeset.changes.kitchen_close_time == 1440
end
```

### Manual Testing
1. Configure a restaurant with 24/7 settings
2. Visit the restaurant page at different times (00:00, 12:00, 23:59)  
3. Verify no "currently closed" message appears
4. Confirm checkout flow works at all times

## Troubleshooting

### Common Issues

1. **Restaurant still shows as closed**: Check that `order_close_time` is exactly `1440` (not `0`)
2. **Validation errors**: Ensure `kitchen_close_time` and `last_delivery_time` allow the auto-adjustment
3. **Weekend issues**: Verify `operating_days` includes weekends (`127` = all days)

### Debug Commands
```bash
# Check restaurant configuration
mix run -e "
  restaurant = Eatfair.Repo.get_by!(Eatfair.Restaurants.Restaurant, name: \"Night Owl Express NL\")
  IO.inspect({restaurant.order_open_time, restaurant.order_close_time})
"

# Test open status
mix run -e "
  restaurant = Eatfair.Repo.get_by!(Eatfair.Restaurants.Restaurant, name: \"Night Owl Express NL\") 
  IO.puts \"Open: #{Eatfair.Restaurants.Restaurant.open_for_orders?(restaurant)}\"
"
```

## Related Files

- `lib/eatfair/restaurants/restaurant.ex` - Main restaurant logic
- `test/eatfair/restaurants/restaurant_operational_hours_test.exs` - Unit tests
- `priv/repo/seeds.exs` - Example 24/7 configuration

## Changes History

- **2025-08-29**: Added explicit 24/7 support with `order_close_time: 1440` convention
- **2025-08-29**: Fixed Night Owl Express NL configuration bug
- **2025-08-29**: Added auto-adjustment of kitchen/delivery times for 24/7 restaurants
