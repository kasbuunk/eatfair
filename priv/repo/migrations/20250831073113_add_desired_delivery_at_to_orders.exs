defmodule Eatfair.Repo.Migrations.AddDesiredDeliveryAtToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :desired_delivery_at, :naive_datetime
      add :eta_accepted, :boolean, default: false
      add :proposed_eta, :naive_datetime
      add :eta_pending, :boolean, default: false
    end

    # Index for efficient queries on desired delivery times
    create index(:orders, [:desired_delivery_at])
    create index(:orders, [:eta_pending])
  end
end
