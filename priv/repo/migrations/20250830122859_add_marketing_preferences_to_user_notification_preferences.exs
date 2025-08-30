defmodule Eatfair.Repo.Migrations.AddMarketingPreferencesToUserNotificationPreferences do
  use Ecto.Migration

  def change do
    alter table(:user_notification_preferences) do
      add :marketing_opt_in, :boolean, null: false, default: false
      add :marketing_opted_in_at, :utc_datetime
      add :marketing_opted_out_at, :utc_datetime
    end
    
    create index(:user_notification_preferences, [:marketing_opt_in])
  end
end
