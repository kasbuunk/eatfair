defmodule Eatfair.Accounts.TermsAcceptance do
  @moduledoc """
  Schema for tracking terms and conditions acceptance for legal compliance.

  This creates an immutable audit trail of when users accept the platform's
  terms and conditions, including version tracking for future terms updates.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User

  schema "terms_acceptances" do
    field :accepted_at, :utc_datetime
    field :terms_version, :string, default: "v1.0"
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(terms_acceptance, attrs) do
    terms_acceptance
    |> cast(attrs, [:user_id, :accepted_at, :terms_version, :ip_address, :user_agent])
    |> validate_required([:user_id, :accepted_at, :terms_version])
    |> validate_length(:terms_version, max: 20)
    |> validate_length(:user_agent, max: 500)
    |> foreign_key_constraint(:user_id)
    |> put_accepted_at_if_missing()
  end

  @doc """
  Creates a terms acceptance record with current timestamp and metadata.
  """
  def create_changeset(attrs, metadata \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:user_id, :terms_version])
    |> put_change(:accepted_at, DateTime.utc_now())
    |> put_change(:ip_address, metadata[:ip_address])
    |> put_change(:user_agent, metadata[:user_agent])
    |> validate_required([:user_id, :accepted_at, :terms_version])
    |> validate_length(:terms_version, max: 20)
    |> validate_length(:user_agent, max: 500)
    |> foreign_key_constraint(:user_id)
  end

  defp put_accepted_at_if_missing(changeset) do
    case get_field(changeset, :accepted_at) do
      nil -> put_change(changeset, :accepted_at, DateTime.utc_now())
      _ -> changeset
    end
  end
end
