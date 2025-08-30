defmodule Eatfair.Repo.Migrations.CreateTermsAcceptances do
  use Ecto.Migration

  def change do
    create table(:terms_acceptances) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :accepted_at, :utc_datetime, null: false
      add :terms_version, :string, size: 20, null: false, default: "v1.0"
      add :ip_address, :string
      add :user_agent, :text
      
      timestamps(type: :utc_datetime)
    end

    create index(:terms_acceptances, [:user_id])
    create index(:terms_acceptances, [:accepted_at])
    create index(:terms_acceptances, [:terms_version])
  end
end
