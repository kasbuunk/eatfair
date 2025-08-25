defmodule Eatfair.Accounts.Address do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User

  schema "addresses" do
    # e.g. "Home", "Work", "Mom's place"
    field :name, :string
    field :street_address, :string
    field :city, :string
    field :postal_code, :string
    field :country, :string, default: "Netherlands"
    field :latitude, :decimal
    field :longitude, :decimal
    field :is_default, :boolean, default: false

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [
      :name,
      :street_address,
      :city,
      :postal_code,
      :country,
      :latitude,
      :longitude,
      :is_default,
      :user_id
    ])
    |> validate_required([:street_address, :city, :postal_code, :user_id])
    |> validate_length(:name, max: 50)
    |> validate_length(:street_address, min: 5, max: 200)
    |> validate_length(:city, min: 2, max: 100)
    |> validate_length(:postal_code, min: 4, max: 10)
    |> foreign_key_constraint(:user_id)
  end
end
