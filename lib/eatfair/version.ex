defmodule Eatfair.Version do
  @moduledoc """
  Application version tracking utilities for telemetry and logging.

  This module provides version information for troubleshooting user-reported 
  issues by including version metadata in all logs and telemetry events.
  """

  @doc """
  Gets the application version from Mix project configuration.

  Returns the version string from mix.exs, fallback to git commit hash
  if available, or "unknown" if neither is available.
  """
  @spec get() :: String.t()
  def get do
    case Mix.Project.config()[:version] do
      nil -> get_git_version()
      version -> version
    end
  end

  @doc """
  Gets git commit hash as version identifier.

  Useful for development builds where Mix.Project version might not
  reflect the actual code state.
  """
  @spec get_git_version() :: String.t()
  def get_git_version do
    case System.cmd("git", ["rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
      {commit_hash, 0} -> String.trim(commit_hash)
      _ -> "unknown"
    end
  end

  @doc """
  Injects version metadata into Logger metadata.

  Call this in your application startup or request lifecycle to ensure
  version information is available in all log entries for request correlation.
  """
  @spec inject_logger_metadata() :: :ok
  def inject_logger_metadata do
    Logger.metadata(version: get())
  end

  @doc """
  Returns version metadata map for telemetry events.

  Use this when emitting telemetry events to include version information
  for debugging version-specific issues.
  """
  @spec telemetry_metadata() :: %{version: String.t()}
  def telemetry_metadata do
    %{version: get()}
  end

  @doc """
  Returns version metadata for OpenTelemetry resource attributes.

  Include this in OpenTelemetry configuration to add version information
  to all spans and traces for comprehensive observability.
  """
  @spec opentelemetry_resource_attributes() :: [{String.t(), String.t()}]
  def opentelemetry_resource_attributes do
    [{"service.version", get()}]
  end
end
