defmodule Eatfair.Repo.Migrations.CreateDeliveryBatches do
  use Ecto.Migration

  def change do
    create table(:delivery_batches) do
      add :name, :string
      add :status, :string
      add :scheduled_pickup_time, :naive_datetime
      add :estimated_delivery_time, :naive_datetime
      add :notes, :text
      add :courier_id, references(:users, on_delete: :nothing)
      add :restaurant_id, references(:restaurants, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:delivery_batches, [:user_id])

    create index(:delivery_batches, [:courier_id])
    create index(:delivery_batches, [:restaurant_id])
  end
end
