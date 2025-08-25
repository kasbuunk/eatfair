defmodule Eatfair.Repo.Migrations.AddGeographicFieldsForDiscovery do
  use Ecto.Migration

  def change do
    # Add geographic coordinates to restaurants
    alter table(:restaurants) do
      add :latitude, :decimal, precision: 10, scale: 8
      add :longitude, :decimal, precision: 11, scale: 8
      add :city, :string
      add :postal_code, :string
      add :country, :string, default: "Netherlands"
    end
    
    # Create addresses table for user address management
    create table(:addresses) do
      add :name, :string  # e.g. "Home", "Work", "Mom's place"
      add :street_address, :string, null: false
      add :city, :string, null: false
      add :postal_code, :string, null: false
      add :country, :string, default: "Netherlands"
      add :latitude, :decimal, precision: 10, scale: 8
      add :longitude, :decimal, precision: 11, scale: 8
      add :is_default, :boolean, default: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      
      timestamps()
    end
    
    create index(:addresses, [:user_id])
    create index(:restaurants, [:latitude, :longitude])
    create index(:addresses, [:latitude, :longitude])
  end
end
