defmodule Ttex.BusSupervisor do
  @moduledoc """
  DynamicSupervisor for bus processes.

  Manages the lifecycle of bus GenServers - allows spawning and terminating
  buses dynamically during the simulation runtime.
  """

  use DynamicSupervisor

  @doc """
  Starts the BusSupervisor.
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Spawns a new bus process under supervision.

  ## Examples

      iex> Ttex.BusSupervisor.start_bus(id: "bus-1", position: {5, 10})
      {:ok, #PID<0.123.0>}
  """
  @spec start_bus(keyword()) :: DynamicSupervisor.on_start_child()
  def start_bus(opts) do
    spec = {Ttex.Bus, opts}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} = result ->
        # Get bus ID and position from opts
        bus_id = Keyword.fetch!(opts, :id)
        {x, y} = Keyword.fetch!(opts, :position)

        # Broadcast spawn notification
        Phoenix.PubSub.broadcast(
          Ttex.PubSub,
          "simulation:position_updates",
          {:entity_spawned, bus_id, x, y, :bus}
        )

        result

      error ->
        error
    end
  end

  @doc """
  Stops a bus process by ID.

  ## Examples

      iex> Ttex.BusSupervisor.stop_bus("bus-1")
      :ok
  """
  def stop_bus(bus_id) do
    case Registry.lookup(Ttex.ProcessRegistry, bus_id) do
      [{pid, _}] ->
        # Broadcast despawn notification before terminating
        Phoenix.PubSub.broadcast(
          Ttex.PubSub,
          "simulation:position_updates",
          {:entity_despawned, bus_id}
        )

        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Lists all running bus PIDs.
  """
  def list_buses do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end

  @doc """
  Counts the number of running buses.
  """
  def count_buses do
    DynamicSupervisor.count_children(__MODULE__).active
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
