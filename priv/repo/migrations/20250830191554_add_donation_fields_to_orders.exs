defmodule Eatfair.Repo.Migrations.AddDonationFieldsToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :donation_amount, :decimal, precision: 10, scale: 2, default: 0.00, null: false
      add :donation_currency, :string, size: 3, default: "EUR", null: false
    end

    create index(:orders, [:donation_amount])
  end
end
