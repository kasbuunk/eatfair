defmodule Eatfair.Repo.Migrations.CreateRefunds do
  use Ecto.Migration

  def change do
    create table(:refunds) do
      add :order_id, references(:orders, on_delete: :nothing), null: false
      add :customer_id, references(:users, on_delete: :nothing), null: false
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :reason, :string, null: false
      add :reason_details, :text
      add :status, :string, default: "pending", null: false
      add :processed_at, :utc_datetime
      add :processor_notes, :text
      add :external_refund_id, :string
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:refunds, [:order_id])
    create index(:refunds, [:customer_id])
    create index(:refunds, [:status])
    create index(:refunds, [:inserted_at])
  end
end
