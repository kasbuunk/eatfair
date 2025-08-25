defmodule Eatfair.Repo.Migrations.AddRestaurantFields do
  use Ecto.Migration

  def change do
    alter table(:restaurants) do
      add :description, :text
      add :cuisine_types, {:array, :string}, default: []
      add :delivery_radius_km, :integer, default: 5
      add :delivery_time_per_km, :integer, default: 3

      # Rename delivery_time to avg_preparation_time for clarity
      # Note: SQLite doesn't support RENAME COLUMN, so we'll add new and remove old
      add :avg_preparation_time, :integer, default: 30
    end

    # Copy data from old field to new field
    execute "UPDATE restaurants SET avg_preparation_time = COALESCE(delivery_time, 30)"

    # Remove old field
    alter table(:restaurants) do
      remove :delivery_time
    end
  end
end
