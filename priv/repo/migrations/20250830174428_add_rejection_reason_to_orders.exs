defmodule Eatfair.Repo.Migrations.AddRejectionReasonToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :rejection_reason, :text
    end
  end
end
