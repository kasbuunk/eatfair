defmodule Eatfair.Repo.Migrations.CreateUserFeedbacks do
  use Ecto.Migration

  def change do
    create table(:user_feedbacks) do
      add :feedback_type, :string, null: false
      add :message, :text, null: false
      add :request_id, :string
      add :page_url, :string
      add :version, :string, null: false
      add :status, :string, default: "new", null: false
      add :admin_notes, :text
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:user_feedbacks, [:user_id])
    create index(:user_feedbacks, [:request_id])
    create index(:user_feedbacks, [:status])
    create index(:user_feedbacks, [:inserted_at])
    create index(:user_feedbacks, [:feedback_type])
  end
end
