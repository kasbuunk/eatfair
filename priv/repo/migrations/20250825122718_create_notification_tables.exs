defmodule Eatfair.Repo.Migrations.CreateNotificationTables do
  use Ecto.Migration

  def change do
    # Notification events table
    create table(:notification_events) do
      add :event_type, :string, null: false
      add :priority, :string, default: "normal", null: false
      add :status, :string, default: "pending", null: false
      # JSON data for notification content
      add :data, :map, null: false
      add :sent_at, :naive_datetime
      add :failed_reason, :string
      add :recipient_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notification_events, [:recipient_id])
    create index(:notification_events, [:event_type])
    create index(:notification_events, [:status])
    create index(:notification_events, [:inserted_at])

    # User notification preferences table
    create table(:user_notification_preferences) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Channel preferences
      add :email_enabled, :boolean, default: true
      add :sms_enabled, :boolean, default: false
      add :push_enabled, :boolean, default: true

      # Content preferences
      add :order_status_notifications, :boolean, default: true
      add :delivery_notifications, :boolean, default: true
      add :marketing_notifications, :boolean, default: false
      add :newsletter_enabled, :boolean, default: false
      add :system_announcements, :boolean, default: true

      # Timing preferences
      add :quiet_hours_start, :time
      add :quiet_hours_end, :time
      add :timezone, :string, default: "Europe/Amsterdam"

      timestamps()
    end

    create unique_index(:user_notification_preferences, [:user_id])
  end
end
