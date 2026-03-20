defmodule Ttex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TtexWeb.Telemetry,
      Ttex.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:ttex, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:ttex, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ttex.PubSub},
      {Registry, keys: :unique, name: Ttex.ProcessRegistry},
      Ttex.BusSupervisor,
      Ttex.SimulationCoordinator,
      {Ttex.WorldClock, interval_ms: 100},
      # Start to serve requests, typically the last entry
      TtexWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ttex.Supervisor]

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      # Spawn initial buses asynchronously (non-blocking)
      Task.start(fn -> spawn_initial_buses() end)
      {:ok, pid}
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TtexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations? do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end

  defp spawn_initial_buses do
    require Logger

    Enum.each(1..50, fn i ->
      {x, y} = Ttex.CityMap.random_position()

      case Ttex.BusSupervisor.start_bus(id: "bus-#{i}", position: {x, y}) do
        {:ok, _pid} ->
          :ok

        {:error, reason} ->
          Logger.warning("Failed to start initial bus bus-#{i}: #{inspect(reason)}")
      end
    end)

    Logger.info("Spawned #{Ttex.BusSupervisor.count_buses()} initial buses")
  end
end
