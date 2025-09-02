defmodule Eatfair.Repo.Migrations.AddStagingAndAutoAssignmentFields do
  use Ecto.Migration

  def change do
    # Add staging fields to orders table
    alter table(:orders) do
      add :staged_at, :naive_datetime
      add :staged, :boolean, default: false
    end

    # Add auto-assignment fields to delivery_batches table
    alter table(:delivery_batches) do
      add :auto_assigned, :boolean, default: false
      add :suggested_courier_id, references(:users, on_delete: :nilify_all)
    end

    # Create index for staged orders query performance
    create index(:orders, [:restaurant_id, :staged], where: "staged = true")
    
    # Create index for auto-assignment queries
    create index(:delivery_batches, [:suggested_courier_id])
  end
end
