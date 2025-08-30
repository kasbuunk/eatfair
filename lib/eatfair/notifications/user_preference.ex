defmodule Eatfair.Notifications.UserPreference do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User

  schema "user_notification_preferences" do
    # Channel preferences
    field :email_enabled, :boolean, default: true
    field :sms_enabled, :boolean, default: false
    field :push_enabled, :boolean, default: true

    # Content preferences
    field :order_status_notifications, :boolean, default: true
    field :delivery_notifications, :boolean, default: true
    field :marketing_notifications, :boolean, default: false
    field :marketing_opt_in, :boolean, default: false
    field :marketing_opted_in_at, :utc_datetime
    field :marketing_opted_out_at, :utc_datetime
    field :newsletter_enabled, :boolean, default: false
    field :system_announcements, :boolean, default: true

    # Timing preferences
    field :quiet_hours_start, :time
    field :quiet_hours_end, :time
    field :timezone, :string, default: "Europe/Amsterdam"

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [
      :user_id,
      :email_enabled,
      :sms_enabled,
      :push_enabled,
      :order_status_notifications,
      :delivery_notifications,
      :marketing_notifications,
      :marketing_opt_in,
      :marketing_opted_in_at,
      :marketing_opted_out_at,
      :newsletter_enabled,
      :system_announcements,
      :quiet_hours_start,
      :quiet_hours_end,
      :timezone
    ])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
