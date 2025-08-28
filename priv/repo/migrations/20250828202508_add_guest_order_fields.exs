defmodule Eatfair.Repo.Migrations.AddGuestOrderFields do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :customer_email, :string
      add :customer_phone, :string
    end
    
    # Note: SQLite doesn't support ALTER COLUMN, so we can't make customer_id nullable
    # For now, we'll handle this constraint in the application code
    # In a PostgreSQL environment, you would uncomment the following:
    # alter table(:orders) do
    #   modify :customer_id, references(:users, on_delete: :nilify_all), null: true
    # end
  end
end
