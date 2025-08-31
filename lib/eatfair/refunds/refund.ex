defmodule Eatfair.Refunds.Refund do
  @moduledoc """
  Schema for staged refunds that need manual processing.

  Refunds are created automatically when orders are rejected or delivery fails,
  but require manual approval and processing before actual money is refunded.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Orders.Order
  alias Eatfair.Accounts.User

  @valid_reasons ["order_rejected", "delivery_failed", "customer_request", "merchant_error"]
  @valid_statuses ["pending", "processing", "processed", "failed", "cancelled"]

  schema "refunds" do
    field :amount, :decimal
    field :reason, :string
    field :reason_details, :string
    field :status, :string, default: "pending"
    field :processed_at, :utc_datetime
    field :processor_notes, :string
    field :external_refund_id, :string

    belongs_to :order, Order
    belongs_to :customer, User
    belongs_to :created_by, User

    timestamps()
  end

  @doc false
  def changeset(refund, attrs) do
    refund
    |> cast(attrs, [
      :order_id,
      :customer_id,
      :amount,
      :reason,
      :reason_details,
      :status,
      :processed_at,
      :processor_notes,
      :external_refund_id,
      :created_by_id
    ])
    |> validate_required([:order_id, :customer_id, :amount, :reason])
    |> validate_inclusion(:reason, @valid_reasons)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:created_by_id)
  end

  @doc false
  def processing_changeset(refund, attrs) do
    refund
    |> cast(attrs, [:status, :processed_at, :processor_notes, :external_refund_id])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
