defmodule Eatfair.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Restaurants.Restaurant
  alias Eatfair.Orders.OrderItem
  alias Eatfair.Orders.Payment
  alias Eatfair.Orders.DeliveryBatch
  alias Eatfair.Accounts.EmailVerification

  @valid_statuses [
    "pending",
    "confirmed",
    "preparing",
    "ready",
    "out_for_delivery",
    "delivered",
    "cancelled",
    "rejected",
    "delivery_failed"
  ]

  schema "orders" do
    field :status, :string, default: "pending"
    field :delivery_status, :string, default: "not_ready"
    field :total_price, :decimal
    field :courier_assigned_at, :naive_datetime
    field :delivery_address, :string
    field :delivery_notes, :string

    # Guest order fields (for streamlined ordering without user accounts)
    field :customer_email, :string
    field :customer_phone, :string

    # Status transition timestamps
    field :confirmed_at, :naive_datetime
    field :preparing_at, :naive_datetime
    field :ready_at, :naive_datetime
    field :out_for_delivery_at, :naive_datetime
    field :delivered_at, :naive_datetime
    field :cancelled_at, :naive_datetime

    # Tracking details
    field :estimated_delivery_at, :naive_datetime
    field :estimated_prep_time_minutes, :integer
    field :actual_prep_time_minutes, :integer

    # Special circumstances
    field :is_delayed, :boolean, default: false
    field :delay_reason, :string
    field :rejection_reason, :string
    field :special_instructions, :string

    # Donation fields
    field :donation_amount, :decimal, default: Decimal.new("0.00")
    field :donation_currency, :string, default: "EUR"

    # Email verification fields
    # unverified, pending, verified
    field :email_status, :string, default: "unverified"
    field :email_verified_at, :utc_datetime
    field :tracking_token, :string
    field :account_created_from_order, :boolean, default: false

    # Customer desired ETA and proposal workflow
    field :desired_delivery_at, :naive_datetime
    field :eta_accepted, :boolean, default: false
    field :proposed_eta, :naive_datetime
    field :eta_pending, :boolean, default: false

    belongs_to :customer, User
    belongs_to :restaurant, Restaurant
    # For future courier assignment
    belongs_to :courier, User
    belongs_to :delivery_batch, DeliveryBatch
    has_many :order_items, OrderItem
    has_one :payment, Payment
    has_many :email_verifications, EmailVerification

    timestamps()
  end

  @valid_delivery_statuses [
    "not_ready",
    "staged",
    "scheduled",
    "in_transit",
    "delivered"
  ]

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :status,
      :delivery_status,
      :total_price,
      :delivery_address,
      :delivery_notes,
      :customer_id,
      :customer_email,
      :customer_phone,
      :restaurant_id,
      :courier_id,
      :delivery_batch_id,
      :confirmed_at,
      :preparing_at,
      :ready_at,
      :out_for_delivery_at,
      :delivered_at,
      :cancelled_at,
      :estimated_delivery_at,
      :estimated_prep_time_minutes,
      :actual_prep_time_minutes,
      :is_delayed,
      :delay_reason,
      :special_instructions,
      :email_status,
      :email_verified_at,
      :tracking_token,
      :account_created_from_order,
      :donation_amount,
      :donation_currency,
      :desired_delivery_at,
      :eta_accepted,
      :proposed_eta,
      :eta_pending
    ])
    |> validate_required([:restaurant_id, :delivery_address])
    |> validate_customer_info()
    |> validate_length(:delivery_address,
      min: 5,
      message: "Please provide a complete delivery address"
    )
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:delivery_status, @valid_delivery_statuses)
    |> validate_number(:total_price, greater_than_or_equal_to: 0)
    |> validate_number(:estimated_prep_time_minutes, greater_than: 0)
    |> validate_number(:actual_prep_time_minutes, greater_than: 0)
    |> validate_number(:donation_amount, greater_than_or_equal_to: 0)
    |> validate_desired_delivery_time()
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:restaurant_id)
    |> foreign_key_constraint(:courier_id)
  end

  # Custom validation to ensure either customer_id (authenticated) or customer_email/phone (guest)
  defp validate_customer_info(changeset) do
    customer_id = get_field(changeset, :customer_id)
    customer_email = get_field(changeset, :customer_email)
    customer_phone = get_field(changeset, :customer_phone)

    cond do
      customer_id != nil ->
        # Authenticated order - customer_id is sufficient
        changeset

      customer_email != nil and customer_phone != nil ->
        # Guest order - validate email and phone
        changeset
        |> validate_required([:customer_email, :customer_phone])
        |> validate_format(:customer_email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
          message: "must be a valid email"
        )
        |> validate_length(:customer_phone,
          min: 8,
          max: 20,
          message: "must be a valid phone number"
        )

      true ->
        # Neither authenticated nor proper guest info
        add_error(
          changeset,
          :customer_id,
          "must provide either customer account or email and phone for guest orders"
        )
    end
  end

  # Custom validation for desired delivery time
  defp validate_desired_delivery_time(changeset) do
    case get_field(changeset, :desired_delivery_at) do
      nil ->
        # Desired delivery time is optional
        changeset

      desired_time ->
        now = NaiveDateTime.utc_now()
        # 30 minutes from now
        min_time = NaiveDateTime.add(now, 30 * 60)
        # 3 days from now
        max_time = NaiveDateTime.add(now, 3 * 24 * 60 * 60)

        cond do
          NaiveDateTime.compare(desired_time, now) != :gt ->
            add_error(changeset, :desired_delivery_at, "must be in the future")

          NaiveDateTime.compare(desired_time, min_time) == :lt ->
            add_error(changeset, :desired_delivery_at, "must be at least 30 minutes from now")

          NaiveDateTime.compare(desired_time, max_time) == :gt ->
            add_error(changeset, :desired_delivery_at, "cannot be more than 3 days in advance")

          true ->
            changeset
        end
    end
  end

  @doc false
  def status_changeset(order, attrs) do
    order
    |> cast(attrs, [
      :status,
      :confirmed_at,
      :preparing_at,
      :ready_at,
      :out_for_delivery_at,
      :delivered_at,
      :cancelled_at,
      :is_delayed,
      :delay_reason,
      :rejection_reason,
      :actual_prep_time_minutes
    ])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_status_transition()
  end

  defp validate_status_transition(changeset) do
    case {get_field(changeset, :status), changeset.data.status} do
      {new_status, old_status} when new_status == old_status ->
        changeset

      # Can cancel from any status
      {"cancelled", _} ->
        changeset

      {"confirmed", "pending"} ->
        changeset

      {"rejected", "pending"} ->
        changeset

      {"preparing", "confirmed"} ->
        changeset

      {"ready", "preparing"} ->
        changeset

      {"out_for_delivery", "ready"} ->
        changeset

      {"delivered", "out_for_delivery"} ->
        changeset

      {"delivery_failed", "out_for_delivery"} ->
        changeset

      {new_status, old_status} ->
        add_error(changeset, :status, "cannot transition from #{old_status} to #{new_status}")
    end
  end

  @doc """
  Generates a secure tracking token for anonymous order tracking.
  """
  def generate_tracking_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end

  @doc """
  Checks if the order email has been verified.
  """
  def email_verified?(%__MODULE__{email_status: "verified"}), do: true
  def email_verified?(%__MODULE__{}), do: false

  @doc """
  Checks if the order is from an authenticated user.
  """
  def authenticated_order?(%__MODULE__{customer_id: nil}), do: false
  def authenticated_order?(%__MODULE__{}), do: true

  @doc """
  Gets the primary email for this order (from customer or guest email).
  """
  def primary_email(%__MODULE__{customer_id: nil, customer_email: email}), do: email
  def primary_email(%__MODULE__{customer: %User{email: email}}), do: email
  def primary_email(_), do: nil
end
