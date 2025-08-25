defmodule Eatfair.Repo.Migrations.AddOrderIdToReviews do
  use Ecto.Migration

  def change do
    alter table(:reviews) do
      add :order_id, references(:orders, on_delete: :delete_all)
    end

    create index(:reviews, [:order_id])

    # NOTE: For existing reviews created before this migration,
    # order_id will be null. These represent pre-launch reviews.
    # All new reviews will require order_id to be set.
  end
end
