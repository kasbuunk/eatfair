defmodule Eatfair.Feedback do
  @moduledoc """
  The Feedback context for managing user feedback submissions.

  This context handles creating, reading, updating, and managing user feedback
  with proper observability metadata for troubleshooting user-reported issues.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Eatfair.Repo
  alias Eatfair.Feedback.UserFeedback

  @doc """
  Creates user feedback with automatic metadata injection.

  ## Examples

      iex> create_user_feedback(%{feedback_type: "bug_report", message: "Something is broken"}, current_scope, %{request_id: "abc123", page_url: "/restaurants"})
      {:ok, %UserFeedback{}}

      iex> create_user_feedback(%{}, nil, %{})
      {:error, %Ecto.Changeset{}}
  """
  def create_user_feedback(attrs, user_scope, metadata \\ %{}) do
    enhanced_attrs =
      attrs
      |> Map.merge(metadata)
      |> Map.put_new(:version, Eatfair.Version.get())

    %UserFeedback{}
    |> UserFeedback.changeset(enhanced_attrs, user_scope)
    |> Repo.insert()
    |> tap(fn
      {:ok, feedback} ->
        # Broadcast real-time update for admin interface
        Phoenix.PubSub.broadcast(
          Eatfair.PubSub,
          "admin:feedback",
          {:new_feedback, feedback}
        )

        # Log feedback creation with correlation metadata
        Logger.info("User feedback submitted",
          feedback_id: feedback.id,
          feedback_type: feedback.feedback_type,
          request_id: feedback.request_id,
          user_id: feedback.user_id,
          version: feedback.version
        )

      {:error, _changeset} ->
        :ok
    end)
  end

  @doc """
  Lists all user feedback with optional filtering and pagination.

  ## Examples

      iex> list_user_feedback()
      [%UserFeedback{}, ...]
      
      iex> list_user_feedback(status: "new", limit: 10)
      [%UserFeedback{}, ...]
  """
  def list_user_feedback(opts \\ []) do
    UserFeedback
    |> filter_by_status(opts[:status])
    |> filter_by_feedback_type(opts[:feedback_type])
    |> order_by([f], desc: f.inserted_at)
    |> maybe_limit(opts[:limit])
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single user feedback by ID.

  ## Examples

      iex> get_user_feedback(123)
      %UserFeedback{}
      
      iex> get_user_feedback(456)
      nil
  """
  def get_user_feedback(id) do
    UserFeedback
    |> preload(:user)
    |> Repo.get(id)
  end

  @doc """
  Gets a single user feedback by ID, raising if not found.

  ## Examples

      iex> get_user_feedback!(123)
      %UserFeedback{}
      
      iex> get_user_feedback!(456)
      ** (Ecto.NoResultsError)
  """
  def get_user_feedback!(id) do
    UserFeedback
    |> preload(:user)
    |> Repo.get!(id)
  end

  @doc """
  Finds feedback by request_id for log correlation.

  ## Examples

      iex> get_feedback_by_request_id("abc123")
      [%UserFeedback{}]
      
      iex> get_feedback_by_request_id("nonexistent")
      []
  """
  def get_feedback_by_request_id(request_id) do
    UserFeedback
    |> where([f], f.request_id == ^request_id)
    |> preload(:user)
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  @doc """
  Updates user feedback status and admin notes.

  ## Examples

      iex> update_feedback_status(feedback, %{status: "resolved", admin_notes: "Fixed in v0.1.1"})
      {:ok, %UserFeedback{}}
      
      iex> update_feedback_status(feedback, %{status: "invalid"})
      {:error, %Ecto.Changeset{}}
  """
  def update_feedback_status(%UserFeedback{} = feedback, attrs) do
    feedback
    |> UserFeedback.admin_changeset(attrs)
    |> Repo.update()
    |> tap(fn
      {:ok, updated_feedback} ->
        # Broadcast update for real-time admin interface
        Phoenix.PubSub.broadcast(
          Eatfair.PubSub,
          "admin:feedback",
          {:feedback_updated, updated_feedback}
        )

      {:error, _changeset} ->
        :ok
    end)
  end

  @doc """
  Deletes user feedback.

  ## Examples

      iex> delete_user_feedback(feedback)
      {:ok, %UserFeedback{}}
      
      iex> delete_user_feedback(feedback)
      {:error, %Ecto.Changeset{}}
  """
  def delete_user_feedback(%UserFeedback{} = feedback) do
    Repo.delete(feedback)
  end

  @doc """
  Returns a changeset for creating user feedback.

  ## Examples

      iex> change_user_feedback()
      %Ecto.Changeset{}
  """
  def change_user_feedback(attrs \\ %{}, user_scope \\ nil) do
    %UserFeedback{}
    |> UserFeedback.changeset(attrs, user_scope)
  end

  @doc """
  Gets feedback statistics for admin dashboard.

  ## Examples

      iex> get_feedback_stats()
      %{total: 42, new: 12, in_progress: 8, resolved: 20, dismissed: 2}
  """
  def get_feedback_stats do
    stats_query =
      from f in UserFeedback,
        group_by: f.status,
        select: {f.status, count(f.id)}

    stats = Repo.all(stats_query) |> Enum.into(%{})

    %{
      total: Repo.aggregate(UserFeedback, :count),
      new: Map.get(stats, "new", 0),
      in_progress: Map.get(stats, "in_progress", 0),
      resolved: Map.get(stats, "resolved", 0),
      dismissed: Map.get(stats, "dismissed", 0)
    }
  end

  # Private helper functions

  defp filter_by_status(query, nil), do: query

  defp filter_by_status(query, status) do
    where(query, [f], f.status == ^status)
  end

  defp filter_by_feedback_type(query, nil), do: query

  defp filter_by_feedback_type(query, feedback_type) do
    where(query, [f], f.feedback_type == ^feedback_type)
  end

  defp maybe_limit(query, nil), do: query

  defp maybe_limit(query, limit) when is_integer(limit) do
    limit(query, ^limit)
  end
end
