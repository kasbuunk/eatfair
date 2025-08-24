defmodule Eatfair.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :rating, :integer, null: false
      add :comment, :text
      add :user_id, references(:users, on_delete: :delete_all)
      add :restaurant_id, references(:restaurants, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:reviews, [:user_id])
    create index(:reviews, [:restaurant_id])
    create index(:reviews, [:restaurant_id, :user_id], unique: true)
  end
end
