defmodule Eatfair.Accounts.UserNotificationPreference do
  @moduledoc """
  User notification preferences schema for marketing and communication settings.

  Tracks user consent and preferences for various types of notifications
  with timestamps for legal compliance.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_notification_preferences" do
    field :marketing_emails, :boolean, default: false
    field :marketing_opt_in_at, :utc_datetime
    field :marketing_opt_out_at, :utc_datetime
    field :order_updates, :boolean, default: true
    field :promotional_sms, :boolean, default: false
    field :newsletter, :boolean, default: false

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for updating notification preferences.

  Automatically sets opt-in/opt-out timestamps based on marketing_emails boolean.
  """
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [
      :user_id,
      :marketing_emails,
      :marketing_opt_in_at,
      :marketing_opt_out_at,
      :order_updates,
      :promotional_sms,
      :newsletter
    ])
    |> validate_required([:user_id])
    |> foreign_key_constraint(:user_id)
    |> set_marketing_timestamps(attrs)
  end

  # Private helper to set marketing opt-in/opt-out timestamps
  defp set_marketing_timestamps(changeset, _attrs) do
    # Handle marketing opt-in/opt-out timestamps
    case get_change(changeset, :marketing_emails) do
      true ->
        changeset
        |> put_change(:marketing_opt_in_at, DateTime.utc_now())
        |> put_change(:marketing_opt_out_at, nil)

      false ->
        changeset
        |> put_change(:marketing_opt_out_at, DateTime.utc_now())

      nil ->
        # No change to marketing_emails, keep existing timestamps
        changeset
    end
  end
end
