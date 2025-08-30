defmodule Eatfair.Repo.Migrations.CreateReviewImages do
  use Ecto.Migration

  def change do
    create table(:review_images) do
      add :review_id, references(:reviews, on_delete: :delete_all), null: false
      add :image_path, :string, size: 500, null: false
      add :position, :integer, default: 1, null: false
      add :compressed_path, :string, size: 500
      add :file_size, :integer
      add :mime_type, :string, size: 50

      timestamps(type: :utc_datetime)
    end

    create unique_index(:review_images, [:review_id, :position])
    create index(:review_images, [:review_id])
  end
end
