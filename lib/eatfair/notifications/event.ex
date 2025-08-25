defmodule Eatfair.Notifications.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Accounts.User

  @valid_event_types [
    "order_status_changed",
    "order_cancelled", 
    "delivery_delayed",
    "newsletter",
    "promotion",
    "system_announcement"
  ]

  @valid_priorities ["low", "normal", "high", "urgent"]

  @valid_statuses ["pending", "sent", "failed", "skipped"]

  schema "notification_events" do
    field :event_type, :string
    field :priority, :string, default: "normal"
    field :status, :string, default: "pending"
    field :data, :map  # JSON data for notification content
    field :sent_at, :naive_datetime
    field :failed_reason, :string

    belongs_to :recipient, User

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_type, :recipient_id, :priority, :status, :data, :sent_at, :failed_reason])
    |> validate_required([:event_type, :recipient_id, :data])
    |> validate_inclusion(:event_type, @valid_event_types)
    |> validate_inclusion(:priority, @valid_priorities)
    |> validate_inclusion(:status, @valid_statuses)
    |> foreign_key_constraint(:recipient_id)
  end

  @doc false
  def status_changeset(event, attrs) do
    event
    |> cast(attrs, [:status, :sent_at, :failed_reason])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
