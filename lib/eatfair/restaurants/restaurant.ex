defmodule Eatfair.Restaurants.Restaurant do
  use Ecto.Schema
  import Ecto.Changeset
  import Bitwise

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Cuisine
  alias Eatfair.Restaurants.Menu

  schema "restaurants" do
    field :name, :string
    field :address, :string
    field :description, :string
    # minutes
    field :avg_preparation_time, :integer, default: 30
    field :delivery_radius_km, :integer, default: 5
    # minutes per km
    field :delivery_time_per_km, :integer, default: 3
    field :min_order_value, :decimal, default: Decimal.new("15.00")
    field :is_open, :boolean, default: true
    field :rating, :decimal
    field :image_url, :string
    field :cuisine_types, {:array, :string}, default: []

    # Operational hours and timezone
    field :timezone, :string, default: "Europe/Amsterdam"
    # All times stored as minutes from midnight (0-1439)
    # 09:00
    field :contact_open_time, :integer, default: 540
    # 22:00
    field :contact_close_time, :integer, default: 1320
    # 10:00
    field :order_open_time, :integer, default: 600
    # 21:00
    field :order_close_time, :integer, default: 1260
    # 10:00
    field :kitchen_open_time, :integer, default: 600
    # 22:00
    field :kitchen_close_time, :integer, default: 1320
    # 23:00
    field :last_delivery_time, :integer, default: 1380
    field :order_cutoff_before_kitchen_close, :integer, default: 30
    field :min_prep_time_for_last_order, :integer, default: 15
    # All days
    field :operating_days, :integer, default: 127
    field :operational_notes, :string
    field :force_closed, :boolean, default: false
    field :force_closed_reason, :string

    # Geographic fields for location-based search
    field :latitude, :decimal
    field :longitude, :decimal
    field :city, :string
    field :postal_code, :string
    field :country, :string, default: "Netherlands"

    belongs_to :owner, User
    many_to_many :cuisines, Cuisine, join_through: "restaurant_cuisines"
    has_many :menus, Menu

    timestamps()
  end

  # Available cuisine options for simple selection
  @cuisine_options [
    "Local/European",
    "Asian/International"
  ]

  def cuisine_options, do: @cuisine_options

  @doc false
  def changeset(restaurant, attrs) do
    restaurant
    |> cast(attrs, [
      :name,
      :address,
      :description,
      :avg_preparation_time,
      :delivery_radius_km,
      :delivery_time_per_km,
      :min_order_value,
      :is_open,
      :rating,
      :image_url,
      :cuisine_types,
      :owner_id,
      :latitude,
      :longitude,
      :city,
      :postal_code,
      :country,
      :timezone,
      :contact_open_time,
      :contact_close_time,
      :order_open_time,
      :order_close_time,
      :kitchen_open_time,
      :kitchen_close_time,
      :last_delivery_time,
      :order_cutoff_before_kitchen_close,
      :min_prep_time_for_last_order,
      :operating_days,
      :operational_notes,
      :force_closed,
      :force_closed_reason
    ])
    |> validate_required([:name, :address, :owner_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:address, min: 5, max: 200)
    |> validate_length(:description, max: 500)
    # max 3 hours
    |> validate_number(:avg_preparation_time, greater_than: 0, less_than: 180)
    |> validate_number(:delivery_radius_km, greater_than: 0, less_than: 50)
    |> validate_number(:delivery_time_per_km, greater_than: 0, less_than: 15)
    |> validate_number(:min_order_value, greater_than_or_equal_to: 0)
    |> validate_number(:rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_cuisine_types()
    |> validate_operational_hours()
    |> foreign_key_constraint(:owner_id)
    |> unique_constraint(:owner_id)
  end

  defp validate_cuisine_types(changeset) do
    validate_change(changeset, :cuisine_types, fn :cuisine_types, types ->
      case Enum.all?(types, &(&1 in @cuisine_options)) do
        true -> []
        false -> [cuisine_types: "contains invalid cuisine type"]
      end
    end)
  end

  defp validate_operational_hours(changeset) do
    changeset
    |> validate_time_range(:contact_open_time, :contact_close_time, "contact hours")
    |> validate_time_range(:order_open_time, :order_close_time, "order hours")
    |> validate_time_range(:kitchen_open_time, :kitchen_close_time, "kitchen hours")
    |> validate_number(:order_cutoff_before_kitchen_close,
      greater_than_or_equal_to: 5,
      less_than_or_equal_to: 120
    )
    |> validate_number(:min_prep_time_for_last_order,
      greater_than_or_equal_to: 5,
      less_than_or_equal_to: 60
    )
    |> validate_number(:operating_days, greater_than: 0, less_than_or_equal_to: 127)
    |> validate_inclusion(:timezone, valid_timezones())
    |> validate_operational_logic()
  end

  defp validate_time_range(changeset, open_field, close_field, description) do
    open_time = get_field(changeset, open_field)
    close_time = get_field(changeset, close_field)

    cond do
      is_nil(open_time) or is_nil(close_time) ->
        changeset

      open_time < 0 or open_time >= 1440 ->
        add_error(
          changeset,
          open_field,
          "#{description} open time must be between 00:00 and 23:59"
        )

      close_time < 0 or close_time > 1440 ->
        add_error(
          changeset,
          close_field,
          "#{description} close time must be between 00:00 and 24:00"
        )

      open_time > close_time and close_time > 0 ->
        # This is likely a midnight crossover - allow it
        changeset

      open_time == close_time ->
        add_error(
          changeset,
          close_field,
          "#{description} close time must be different from open time"
        )

      true ->
        changeset
    end
  end

  defp validate_operational_logic(changeset) do
    order_open = get_field(changeset, :order_open_time)
    order_close = get_field(changeset, :order_close_time)
    kitchen_close = get_field(changeset, :kitchen_close_time)
    cutoff_buffer = get_field(changeset, :order_cutoff_before_kitchen_close)

    cond do
      is_nil(order_close) or is_nil(kitchen_close) or is_nil(cutoff_buffer) ->
        changeset

      # Special case for 24/7 operations: order_open_time == 0 and order_close_time == 1440
      order_open == 0 and order_close == 1440 ->
        # For 24/7 restaurants, ensure kitchen also operates 24/7 or at least has appropriate hours
        if kitchen_close < 1440 do
          changeset
          # Auto-adjust kitchen to 24/7
          |> put_change(:kitchen_close_time, 1440)
          # Auto-adjust delivery time
          |> put_change(:last_delivery_time, 1440)
        else
          changeset
        end

      # Last order time should be before kitchen closes minus buffer (normal case)
      order_close > kitchen_close - cutoff_buffer ->
        add_error(
          changeset,
          :order_close_time,
          "order acceptance must end #{cutoff_buffer} minutes before kitchen closes"
        )

      true ->
        changeset
    end
  end

  # Comprehensive timezone list for restaurant locations
  defp valid_timezones do
    [
      # Europe
      "Europe/Amsterdam",
      "Europe/Berlin",
      "Europe/Paris",
      "Europe/London",
      "Europe/Rome",
      "Europe/Madrid",
      "Europe/Brussels",
      "Europe/Vienna",
      "Europe/Zurich",
      "Europe/Stockholm",
      "Europe/Oslo",
      "Europe/Copenhagen",

      # North America
      "America/New_York",
      "America/Chicago",
      "America/Denver",
      "America/Los_Angeles",
      "America/Toronto",
      "America/Vancouver",
      "America/Montreal",

      # Asia Pacific
      "Asia/Tokyo",
      "Asia/Shanghai",
      "Asia/Hong_Kong",
      "Asia/Singapore",
      "Australia/Sydney",
      "Australia/Melbourne",
      "Pacific/Auckland"
    ]
  end

  @doc """
  Checks if restaurant is currently open for orders based on timezone and operational hours.
  """
  def open_for_orders?(%__MODULE__{} = restaurant) do
    if restaurant.force_closed do
      false
    else
      now = DateTime.now!(restaurant.timezone)
      current_day = Date.day_of_week(now)
      current_minute = now.hour * 60 + now.minute

      day_bit = :math.pow(2, current_day - 1) |> round()
      operating_today? = (restaurant.operating_days &&& day_bit) > 0

      # Special case for 24/7 operations (order_open_time: 0, order_close_time: 1440)
      within_hours? =
        if restaurant.order_open_time == 0 and restaurant.order_close_time == 1440 do
          # Always within hours for 24/7 operation
          true
        else
          current_minute >= restaurant.order_open_time and
            current_minute < restaurant.order_close_time
        end

      operating_today? and within_hours?
    end
  end

  @doc """
  Gets the latest time orders can be placed today (in restaurant's timezone).
  Returns nil if restaurant is closed today.
  """
  def last_order_time_today(%__MODULE__{} = restaurant) do
    if open_for_orders?(restaurant) do
      restaurant_tz = restaurant.timezone
      today = DateTime.now!(restaurant_tz) |> DateTime.to_date()

      # Calculate actual last order time (kitchen close - buffer)
      last_order_minute =
        restaurant.kitchen_close_time - restaurant.order_cutoff_before_kitchen_close

      last_order_minute = min(last_order_minute, restaurant.order_close_time)

      hours = div(last_order_minute, 60)
      minutes = rem(last_order_minute, 60)

      {:ok, time} = Time.new(hours, minutes, 0)
      {:ok, datetime} = DateTime.new(today, time, restaurant_tz)

      datetime
    else
      nil
    end
  end

  @doc """
  Converts minutes from midnight to HH:MM format.
  """
  def minutes_to_time(minutes) when is_integer(minutes) and minutes >= 0 and minutes < 1440 do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)

    String.pad_leading(to_string(hours), 2, "0") <>
      ":" <> String.pad_leading(to_string(mins), 2, "0")
  end

  # Handle end of day
  def minutes_to_time(1440), do: "24:00"
  def minutes_to_time(_), do: "Invalid"

  @doc """
  Converts HH:MM time string to minutes from midnight.
  """
  def time_to_minutes(time_string) when is_binary(time_string) do
    case String.split(time_string, ":") do
      [hour_str, minute_str] ->
        with {hour, ""} <- Integer.parse(hour_str),
             {minute, ""} <- Integer.parse(minute_str),
             true <- hour >= 0 and hour <= 24,
             true <- minute >= 0 and minute < 60 do
          if hour == 24 and minute == 0 do
            # Special case for midnight next day
            1440
          else
            hour * 60 + minute
          end
        else
          _ -> {:error, :invalid_time}
        end

      _ ->
        {:error, :invalid_format}
    end
  end
end
