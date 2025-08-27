defmodule Eatfair.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Load .env file at application startup for development and test environments
    load_dotenv()
    
    children = [
      EatfairWeb.Telemetry,
      Eatfair.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:eatfair, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:eatfair, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Eatfair.PubSub},
      # Start a worker by calling: Eatfair.Worker.start_link(arg)
      # {Eatfair.Worker, arg},
      # Start to serve requests, typically the last entry
      EatfairWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Eatfair.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EatfairWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
  
  defp load_dotenv do
    # Load .env file for development and test environments
    # Skip in production to avoid overriding system environment variables
    case Mix.env() do
      env when env in [:dev, :test] ->
        env_file = Path.join(File.cwd!(), ".env")
        
        if File.exists?(env_file) do
          case Dotenvy.source(env_file) do
            {:ok, env_vars} ->
              # Log successful loading (only in development)
              if Mix.env() == :dev do
                require Logger
                var_count = Enum.count(env_vars)
                Logger.info("Loaded #{var_count} environment variables from .env file")
              end
              
            {:error, reason} ->
              # Log error but don't crash the application
              require Logger
              Logger.warning("Failed to load .env file: #{inspect(reason)}")
          end
        else
          # .env file doesn't exist, that's okay
          if Mix.env() == :dev do
            require Logger
            Logger.debug("No .env file found, using system environment variables")
          end
        end
        
      :prod ->
        # In production, rely on system environment variables
        # Don't load .env files to avoid security issues
        :skip
    end
  end
end
