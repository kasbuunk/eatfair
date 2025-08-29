defmodule Eatfair.Repo.Migrations.AddEmailVerificationToOrders do
  use Ecto.Migration

  def change do
    # Add email verification fields to orders
    alter table(:orders) do
      add :email_status, :string, default: "unverified" # unverified, pending, verified
      add :email_verified_at, :utc_datetime
      add :tracking_token, :string # for anonymous tracking
      add :account_created_from_order, :boolean, default: false
    end

    # Create email_verifications table for managing verification tokens
    create table(:email_verifications) do
      add :email, :string, null: false
      add :token, :string, null: false, size: 64
      add :verified_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false
      add :order_id, references(:orders, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    # Add indexes for performance
    create index(:orders, [:email_status])
    create unique_index(:orders, [:tracking_token])
    create index(:email_verifications, [:email])
    create unique_index(:email_verifications, [:token])
    create index(:email_verifications, [:order_id])
    create index(:email_verifications, [:user_id])
    create index(:email_verifications, [:expires_at])
  end
end
