defmodule Eatfair.Orders.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Orders.Order

  @valid_statuses ["pending", "processing", "completed", "failed", "refunded"]

  schema "payments" do
    field :amount, :decimal
    field :status, :string, default: "pending"
    field :provider_transaction_id, :string

    belongs_to :order, Order

    timestamps()
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:amount, :status, :provider_transaction_id, :order_id])
    |> validate_required([:amount, :order_id])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:order_id)
    |> unique_constraint(:order_id)
  end

  @doc false
  def status_changeset(payment, attrs) do
    payment
    |> cast(attrs, [:status, :provider_transaction_id])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
