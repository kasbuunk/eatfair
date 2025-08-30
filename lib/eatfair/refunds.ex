defmodule Eatfair.Refunds do
  @moduledoc """
  The Refunds context for managing staged refunds.
  
  This context handles creating refund records that stage refunds for manual processing,
  without actually processing the refund immediately. This allows for fraud prevention,
  manual review, and different refund policies based on the situation.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Refunds.Refund
  alias Eatfair.Orders.Order

  @doc """
  Creates a staged refund for an order.

  ## Examples

      iex> create_refund_for_order(order, %{reason: "order_rejected"})
      {:ok, %Refund{}}

      iex> create_refund_for_order(order, %{reason: "invalid_reason"})
      {:error, %Ecto.Changeset{}}

  """
  def create_refund_for_order(%Order{} = order, attrs) when is_map(attrs) do
    refund_attrs = %{
      order_id: order.id,
      customer_id: order.customer_id,
      amount: order.total_price,
      reason: attrs[:reason] || attrs["reason"],
      reason_details: attrs[:reason_details] || attrs["reason_details"],
      status: "pending"
    }

    %Refund{}
    |> Refund.changeset(refund_attrs)
    |> Repo.insert()
  end

  @doc """
  Returns all pending refunds that need manual processing.

  ## Examples

      iex> list_pending_refunds()
      [%Refund{}, ...]

  """
  def list_pending_refunds do
    Refund
    |> where([r], r.status == "pending")
    |> preload([:order, :customer])
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets all refunds for a specific order.

  ## Examples

      iex> get_refunds_for_order(123)
      [%Refund{}, ...]

  """
  def get_refunds_for_order(order_id) when is_integer(order_id) do
    Refund
    |> where([r], r.order_id == ^order_id)
    |> preload([:order, :customer])
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
  end

  @doc """
  Marks a refund as processed with processing details.

  ## Examples

      iex> mark_refund_processed(refund, %{processor_notes: "Processed via Stripe"})
      {:ok, %Refund{}}

  """
  def mark_refund_processed(%Refund{} = refund, attrs) when is_map(attrs) do
    processing_attrs =
      attrs
      |> Map.put(:status, "processed")
      |> Map.put(:processed_at, DateTime.utc_now())

    refund
    |> Refund.processing_changeset(processing_attrs)
    |> Repo.update()
  end

  @doc """
  Gets a refund by ID with preloaded associations.

  Raises `Ecto.NoResultsError` if the Refund does not exist.

  ## Examples

      iex> get_refund!(123)
      %Refund{}

      iex> get_refund!(456)
      ** (Ecto.NoResultsError)

  """
  def get_refund!(id) do
    Refund
    |> preload([:order, :customer, :created_by])
    |> Repo.get!(id)
  end

  @doc """
  Updates a refund.

  ## Examples

      iex> update_refund(refund, %{status: "processing"})
      {:ok, %Refund{}}

      iex> update_refund(refund, %{status: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_refund(%Refund{} = refund, attrs) do
    refund
    |> Refund.processing_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a refund changeset for tracking refund changes.

  ## Examples

      iex> change_refund(refund)
      %Ecto.Changeset{data: %Refund{}}

  """
  def change_refund(%Refund{} = refund, attrs \\ %{}) do
    Refund.changeset(refund, attrs)
  end
end
