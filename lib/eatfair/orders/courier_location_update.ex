defmodule Eatfair.Orders.CourierLocationUpdate do
  @moduledoc """
  Schema for tracking courier location updates during order delivery.

  This table stores real-time location data from couriers for orders in transit,
  allowing customers to track their delivery progress on a map.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Orders.Order
  alias Eatfair.Accounts.User

  schema "courier_location_updates" do
    field :latitude, :decimal
    field :longitude, :decimal
    field :accuracy_meters, :integer
    field :recorded_at, :utc_datetime
    field :delivery_queue_position, :integer
    field :estimated_arrival, :utc_datetime

    belongs_to :order, Order
    belongs_to :courier, User

    timestamps()
  end

  @doc false
  def changeset(courier_location_update, attrs) do
    courier_location_update
    |> cast(attrs, [
      :order_id,
      :courier_id,
      :latitude,
      :longitude,
      :accuracy_meters,
      :recorded_at,
      :delivery_queue_position,
      :estimated_arrival
    ])
    |> validate_required([:order_id, :courier_id, :latitude, :longitude, :recorded_at])
    |> validate_location_coordinates()
    |> validate_number(:accuracy_meters, greater_than_or_equal_to: 0)
    |> validate_number(:delivery_queue_position, greater_than_or_equal_to: 0)
    |> validate_recorded_at_not_future()
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:courier_id)
  end

  @doc """
  Creates a changeset for a new location update with default recorded_at to now.
  """
  def create_changeset(attrs) do
    attrs_with_defaults =
      attrs
      |> Map.put_new(:recorded_at, DateTime.utc_now())

    %__MODULE__{}
    |> changeset(attrs_with_defaults)
  end

  defp validate_location_coordinates(changeset) do
    changeset
    |> validate_latitude()
    |> validate_longitude()
  end

  defp validate_latitude(changeset) do
    case get_field(changeset, :latitude) do
      nil ->
        changeset

      lat when is_number(lat) ->
        if lat >= -90.0 and lat <= 90.0 do
          changeset
        else
          add_error(changeset, :latitude, "must be between -90.0 and 90.0")
        end

      _ ->
        add_error(changeset, :latitude, "must be a valid number")
    end
  end

  defp validate_longitude(changeset) do
    case get_field(changeset, :longitude) do
      nil ->
        changeset

      lng when is_number(lng) ->
        if lng >= -180.0 and lng <= 180.0 do
          changeset
        else
          add_error(changeset, :longitude, "must be between -180.0 and 180.0")
        end

      _ ->
        add_error(changeset, :longitude, "must be a valid number")
    end
  end

  defp validate_recorded_at_not_future(changeset) do
    case get_field(changeset, :recorded_at) do
      nil ->
        changeset

      recorded_at ->
        if DateTime.compare(recorded_at, DateTime.utc_now()) == :gt do
          add_error(changeset, :recorded_at, "cannot be in the future")
        else
          changeset
        end
    end
  end

  @doc """
  Calculates distance between two location points using the Haversine formula.
  Returns distance in kilometers.
  """
  def distance_between(%__MODULE__{latitude: lat1, longitude: lng1}, %{
        latitude: lat2,
        longitude: lng2
      }) do
    distance_between({lat1, lng1}, {lat2, lng2})
  end

  def distance_between({lat1, lng1}, {lat2, lng2}) do
    # Convert coordinates to Decimal if they aren't already numbers
    lat1 = decimal_to_float(lat1)
    lng1 = decimal_to_float(lng1)
    lat2 = decimal_to_float(lat2)
    lng2 = decimal_to_float(lng2)

    # Haversine formula
    dlat = deg_to_rad(lat2 - lat1)
    dlng = deg_to_rad(lng2 - lng1)

    a =
      :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(deg_to_rad(lat1)) * :math.cos(deg_to_rad(lat2)) *
          :math.pow(:math.sin(dlng / 2), 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    # Earth's radius in kilometers
    6371 * c
  end

  defp decimal_to_float(%Decimal{} = decimal), do: Decimal.to_float(decimal)
  defp decimal_to_float(number) when is_number(number), do: number

  # Convert degrees to radians
  defp deg_to_rad(degrees), do: degrees * :math.pi() / 180

  @doc """
  Estimates delivery time based on distance and average delivery speed.
  Returns estimated minutes to delivery.
  """
  def estimate_delivery_time(distance_km, avg_speed_kmh \\ 25) do
    # Calculate time in hours, then convert to minutes
    time_hours = distance_km / avg_speed_kmh
    round(time_hours * 60)
  end
end
