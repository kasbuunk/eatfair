defmodule Eatfair.Feedback.UserFeedback do
  @moduledoc """
  Schema for user feedback submissions with observability metadata.

  This schema captures user feedback along with request correlation data
  for troubleshooting and development purposes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @feedback_types ["bug_report", "feature_request", "general_feedback", "usability_issue"]
  @statuses ["new", "in_progress", "resolved", "dismissed"]

  schema "user_feedbacks" do
    field :feedback_type, :string
    field :message, :string
    field :request_id, :string
    field :page_url, :string
    field :version, :string
    field :status, :string, default: "new"
    field :admin_notes, :string

    belongs_to :user, Eatfair.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating user feedback submissions.

  Automatically sets user_id from scope and injects version/request metadata.
  """
  def changeset(user_feedback, attrs, user_scope \\ nil) do
    user_feedback
    |> cast(attrs, [:feedback_type, :message, :request_id, :page_url, :version, :admin_notes])
    |> validate_required([:feedback_type, :message])
    |> validate_inclusion(:feedback_type, @feedback_types)
    |> validate_length(:message, min: 10, max: 5000)
    |> maybe_put_user_id(user_scope)
    |> put_version_if_missing()
  end

  @doc """
  Changeset for admin updates to feedback status and notes.
  """
  def admin_changeset(user_feedback, attrs) do
    user_feedback
    |> cast(attrs, [:status, :admin_notes])
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:admin_notes, max: 2000)
  end

  defp maybe_put_user_id(changeset, %{user: %{id: user_id}}) do
    put_change(changeset, :user_id, user_id)
  end

  defp maybe_put_user_id(changeset, _), do: changeset

  defp put_version_if_missing(changeset) do
    case get_field(changeset, :version) do
      nil -> put_change(changeset, :version, Eatfair.Version.get())
      _ -> changeset
    end
  end
end
