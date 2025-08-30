defmodule Eatfair.Repo.Migrations.AddRestaurantOperationalHours do
  use Ecto.Migration

  def change do
    alter table(:restaurants) do
      # Timezone - essential for time calculations
      add :timezone, :string, null: false, default: "Europe/Amsterdam"

      # Core operational hours (stored as minutes from midnight, 0-1439)
      # This avoids complex time parsing and makes calculations simple
      # 09:00
      add :contact_open_time, :integer, null: false, default: 540
      # 22:00
      add :contact_close_time, :integer, null: false, default: 1320

      # Order acceptance window (typically inside contact hours)
      # 10:00
      add :order_open_time, :integer, null: false, default: 600
      # 21:00
      add :order_close_time, :integer, null: false, default: 1260

      # Kitchen operation (must accommodate last orders + prep time)
      # 10:00
      add :kitchen_open_time, :integer, null: false, default: 600
      # 22:00
      add :kitchen_close_time, :integer, null: false, default: 1320

      # Latest delivery time (can extend beyond kitchen close)
      # 23:00
      add :last_delivery_time, :integer, null: false, default: 1380

      # Buffer times (in minutes)
      add :order_cutoff_before_kitchen_close, :integer, null: false, default: 30
      add :min_prep_time_for_last_order, :integer, null: false, default: 15

      # Days of operation (bitmask: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64)
      # All days (1+2+4+8+16+32+64)
      add :operating_days, :integer, null: false, default: 127

      # Special operational notes
      add :operational_notes, :string

      # Override for manual control (emergency closures, etc.)
      add :force_closed, :boolean, null: false, default: false
      add :force_closed_reason, :string
    end

    # Note: SQLite doesn't support ADD CONSTRAINT in ALTER TABLE
    # We'll rely on application-level validation for constraints

    # Index for timezone-based queries
    create index(:restaurants, [:timezone])
  end
end
