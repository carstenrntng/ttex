defmodule Ttex.SimulationCoordinator do
  @moduledoc """
  Simulation Coordinator GenServer that orchestrates the simulation tick cycle.

  Responsibilities:
  1. Receive tick messages from World Clock
  2. Query Registry for all active entities (buses, citizens)
  3. Send tick to each entity
  4. Collect position updates
  5. Broadcast batch update to LiveView via PubSub
  """

  use GenServer
  require Logger

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    state = %{
      tick_count: 0,
      last_tick_duration_ms: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_info({:tick, timestamp}, state) do
    start_time = System.monotonic_time(:microsecond)

    # Query all entities from Registry
    entities = query_all_entities()

    # Send tick to each entity
    send_ticks_to_entities(entities, timestamp)

    # Query positions after tick processing
    updated_entities = query_all_entities()

    # Broadcast batch update to LiveView
    broadcast_entities(updated_entities)

    # Calculate tick processing duration
    end_time = System.monotonic_time(:microsecond)
    duration_ms = (end_time - start_time) / 1000

    new_state = %{
      state
      | tick_count: state.tick_count + 1,
        last_tick_duration_ms: duration_ms
    }

    {:noreply, new_state}
  end

  # Private Helpers

  defp query_all_entities do
    # Query buses from Registry
    buses =
      Registry.select(Ttex.ProcessRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
      |> Enum.filter(fn {id, _pid} -> String.starts_with?(id, "bus-") end)
      |> Task.async_stream(
        fn {id, pid} ->
          try do
            position = Ttex.Bus.position(pid)
            {x, y} = position
            %{id: id, x: x, y: y, type: :bus}
          catch
            :exit, _ -> nil
          end
        end,
        timeout: :infinity,
        max_concurrency: 50
      )
      |> Enum.reduce([], fn
        {:ok, nil}, acc -> acc
        {:ok, entity}, acc -> [entity | acc]
      end)

    # Future: Add citizens here
    # citizens = query_citizens()

    buses
  end

  defp send_ticks_to_entities(entities, timestamp) do
    # Send tick message to each entity process
    Enum.each(entities, fn entity ->
      case Registry.lookup(Ttex.ProcessRegistry, entity.id) do
        [{pid, _}] -> send(pid, {:tick, timestamp})
        [] -> :ok
      end
    end)

    # Give entities time to process tick
    # In a real system, you might want to wait for acknowledgments
    Process.sleep(10)
  end

  defp broadcast_entities(entities) do
    Phoenix.PubSub.broadcast(
      Ttex.PubSub,
      "simulation:entities",
      {:entities_updated, entities}
    )
  end
end
