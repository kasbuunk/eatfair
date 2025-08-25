defmodule Eatfair.Repo.Migrations.EnhanceOrdersForTracking do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      # Status transition timestamps
      add :confirmed_at, :naive_datetime
      add :preparing_at, :naive_datetime
      add :ready_at, :naive_datetime
      add :out_for_delivery_at, :naive_datetime
      add :delivered_at, :naive_datetime
      add :cancelled_at, :naive_datetime

      # Tracking details
      add :estimated_delivery_at, :naive_datetime
      # Restaurant's estimate
      add :estimated_prep_time_minutes, :integer
      # Actual time taken
      add :actual_prep_time_minutes, :integer

      # Courier assignment (for future use)
      add :courier_id, references(:users, on_delete: :nilify_all)
      add :courier_assigned_at, :naive_datetime

      # Special circumstances
      add :is_delayed, :boolean, default: false
      add :delay_reason, :string
      # From customer or restaurant
      add :special_instructions, :text
    end

    create index(:orders, [:courier_id])
    create index(:orders, [:status])
    create index(:orders, [:confirmed_at])
    create index(:orders, [:estimated_delivery_at])
  end
end
