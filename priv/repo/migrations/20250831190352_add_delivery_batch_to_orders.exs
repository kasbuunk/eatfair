defmodule Eatfair.Repo.Migrations.AddDeliveryBatchToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :delivery_batch_id, references(:delivery_batches, on_delete: :nilify_all)
    end

    create index(:orders, [:delivery_batch_id])
  end
end
