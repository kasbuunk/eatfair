defmodule Eatfair.Accounts.EmailVerification do
  @moduledoc """
  Schema for managing email verification tokens.

  This schema handles the email verification process for both anonymous orders
  and user account creation, supporting the progressive email verification flow
  where users can verify their email at various stages of the order process.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User
  alias Eatfair.Orders.Order

  schema "email_verifications" do
    field :email, :string
    field :token, :string
    field :verified_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :order, Order
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(email_verification, attrs) do
    email_verification
    |> cast(attrs, [:email, :token, :verified_at, :expires_at, :order_id, :user_id])
    |> validate_required([:email, :token, :expires_at])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:token, is: 43)
    |> unique_constraint(:token)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Generates a secure random token for email verification.
  """
  def generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  @doc """
  Checks if the verification token is still valid (not expired).
  """
  def valid?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end

  @doc """
  Checks if the email has been verified.
  """
  def verified?(%__MODULE__{verified_at: nil}), do: false
  def verified?(%__MODULE__{verified_at: _}), do: true
end
