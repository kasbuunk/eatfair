defmodule Eatfair.FileUpload do
  @moduledoc """
  Handles file uploads to local filesystem for development and testing.
  
  ADR: Using local filesystem storage for MVP to avoid external dependencies.
  Future: Can be extended with cloud storage adapters (S3, CloudFlare, etc.)
  """

  @upload_dir "priv/static/uploads"
  @allowed_extensions [".jpg", ".jpeg", ".png", ".gif", ".webp"]
  @max_file_size 5_000_000  # 5MB

  def upload_dir, do: @upload_dir
  def max_file_size, do: @max_file_size
  def allowed_extensions, do: @allowed_extensions

  @doc """
  Saves an uploaded file to the local filesystem.
  Returns {:ok, relative_path} or {:error, reason}
  """
  def save_upload(%Phoenix.LiveView.UploadEntry{} = entry, subfolder \\ "restaurants") do
    # Ensure upload directory exists
    full_upload_dir = Path.join([@upload_dir, subfolder])
    File.mkdir_p!(full_upload_dir)

    # Generate unique filename
    extension = Path.extname(entry.client_name)
    filename = "#{generate_filename()}#{extension}"
    file_path = Path.join([full_upload_dir, filename])

    # Copy uploaded file
    case File.cp(entry.path, file_path) do
      :ok -> 
        # Return relative path for database storage
        relative_path = Path.join(["/uploads", subfolder, filename])
        {:ok, relative_path}
      {:error, reason} -> 
        {:error, "Failed to save file: #{reason}"}
    end
  end

  @doc """
  Validates file extension and size
  """
  def validate_upload(%Phoenix.LiveView.UploadEntry{} = entry) do
    errors = []

    # Check file extension
    extension = Path.extname(entry.client_name) |> String.downcase()
    errors = if extension in @allowed_extensions do
      errors
    else
      ["Invalid file type. Allowed: #{Enum.join(@allowed_extensions, ", ")}" | errors]
    end

    # Check file size
    errors = if entry.client_size <= @max_file_size do
      errors
    else
      size_mb = Float.round(entry.client_size / 1_000_000, 1)
      max_mb = Float.round(@max_file_size / 1_000_000, 1)
      ["File too large (#{size_mb}MB). Maximum size: #{max_mb}MB" | errors]
    end

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Deletes a file from local storage
  """
  def delete_file(relative_path) when is_binary(relative_path) do
    # Convert relative path to absolute
    absolute_path = Path.join(["priv/static", relative_path])
    
    case File.rm(absolute_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok  # File doesn't exist, that's fine
      {:error, reason} -> {:error, "Failed to delete file: #{reason}"}
    end
  end

  # Generate unique filename using timestamp and random string
  defp generate_filename do
    timestamp = System.system_time(:second)
    random = :crypto.strong_rand_bytes(8) |> Base.encode32() |> binary_part(0, 8)
    "#{timestamp}_#{random}"
  end
end
