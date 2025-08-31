defmodule Eatfair.Repo.Migrations.AddDeliveryStatusToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :delivery_status, :string, default: "not_ready", null: false
    end

    # Add index for efficient querying by delivery status
    create index(:orders, [:delivery_status])
    
    # Add composite index for restaurant + delivery status queries
    create index(:orders, [:restaurant_id, :delivery_status])
  end
end
