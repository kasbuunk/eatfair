defmodule Eatfair.Repo.Migrations.CreateOrderTrackingAuditSystem do
  use Ecto.Migration

  def change do
    # Create order_status_events table for immutable status tracking
    create table(:order_status_events) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :occurred_at, :utc_datetime, null: false
      add :actor_id, references(:users, on_delete: :nilify_all)
      # 'customer', 'restaurant', 'courier', 'system'
      add :actor_type, :string, null: false
      # JSONB-like storage for status-specific data
      add :metadata, :map
      # Optional human-readable notes
      add :notes, :text

      # created_at tracks when record was inserted
      timestamps()
    end

    # Create courier_location_updates table for real-time tracking
    create table(:courier_location_updates) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :courier_id, references(:users, on_delete: :nilify_all), null: false
      add :latitude, :decimal, precision: 10, scale: 8, null: false
      add :longitude, :decimal, precision: 11, scale: 8, null: false
      add :accuracy_meters, :integer
      add :recorded_at, :utc_datetime, null: false
      # how many deliveries before this one
      add :delivery_queue_position, :integer
      add :estimated_arrival, :utc_datetime

      timestamps()
    end

    # Indexes for efficient querying
    create index(:order_status_events, [:order_id, :occurred_at])
    create index(:order_status_events, [:status, :occurred_at])
    create index(:order_status_events, [:actor_id])
    create index(:order_status_events, [:actor_type])

    create index(:courier_location_updates, [:order_id, :recorded_at])
    create index(:courier_location_updates, [:courier_id, :recorded_at])
  end
end
