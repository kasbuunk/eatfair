defmodule Eatfair.Reviews.ReviewImage do
  @moduledoc """
  Schema for review images uploaded by customers.

  Each review can have multiple images (up to 3) with proper ordering,
  compression, and security validation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Eatfair.Reviews.Review

  @max_images_per_review 3
  @allowed_mime_types ["image/jpeg", "image/png", "image/webp"]
  # 5MB
  @max_file_size 5_000_000

  schema "review_images" do
    field :image_path, :string
    field :position, :integer, default: 1
    field :compressed_path, :string
    field :file_size, :integer
    field :mime_type, :string

    belongs_to :review, Review

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review_image, attrs) do
    review_image
    |> cast(attrs, [:review_id, :image_path, :position, :compressed_path, :file_size, :mime_type])
    |> validate_required([:review_id, :image_path, :position])
    |> validate_number(:position, greater_than: 0, less_than_or_equal_to: @max_images_per_review)
    |> validate_number(:file_size, greater_than: 0, less_than_or_equal_to: @max_file_size)
    |> validate_inclusion(:mime_type, @allowed_mime_types)
    |> validate_length(:image_path, min: 1, max: 500)
    |> validate_length(:compressed_path, max: 500)
    |> foreign_key_constraint(:review_id)
    |> unique_constraint([:review_id, :position])
  end

  @doc """
  Creates a changeset for image upload validation.
  """
  def upload_changeset(review_image, attrs, upload_entry) do
    review_image
    |> changeset(attrs)
    |> validate_upload_entry(upload_entry)
  end

  # Private helper to validate file upload entry
  defp validate_upload_entry(changeset, %Phoenix.LiveView.UploadEntry{} = entry) do
    changeset
    |> put_change(:file_size, entry.client_size)
    |> put_change(:mime_type, entry.client_type)
    |> validate_upload_file_type(entry)
    |> validate_upload_file_size(entry)
  end

  defp validate_upload_entry(changeset, _), do: changeset

  defp validate_upload_file_type(changeset, entry) do
    if entry.client_type in @allowed_mime_types do
      changeset
    else
      add_error(
        changeset,
        :mime_type,
        "Invalid file type. Only JPEG, PNG, and WebP images are allowed."
      )
    end
  end

  defp validate_upload_file_size(changeset, entry) do
    if entry.client_size <= @max_file_size do
      changeset
    else
      size_mb = Float.round(entry.client_size / 1_000_000, 1)
      max_mb = Float.round(@max_file_size / 1_000_000, 1)

      add_error(
        changeset,
        :file_size,
        "File too large (#{size_mb}MB). Maximum size: #{max_mb}MB"
      )
    end
  end

  @doc """
  Returns the maximum number of images allowed per review.
  """
  def max_images_per_review, do: @max_images_per_review

  @doc """
  Returns the list of allowed MIME types for image uploads.
  """
  def allowed_mime_types, do: @allowed_mime_types

  @doc """
  Returns the maximum file size allowed for image uploads.
  """
  def max_file_size, do: @max_file_size
end
