defmodule Ttex.SimulationCoordinator do
  @moduledoc """
  Event-Driven Simulation Coordinator (Pure Passive Aggregator).

  ## Architecture: Push, Never Pull

  The coordinator NEVER queries or fetches entity state. It only:
  1. **Receives** position update events pushed by entities
  2. **Caches** them in an in-memory map (entity_id => position)
  3. **Broadcasts** batched updates to LiveView when signaled

  ## Why This Scales

  - **No Registry queries** - entities push updates, we just receive
  - **No GenServer calls** - no Task.async_stream overhead
  - **Parallel entity processing** - all entities update simultaneously
  - **Instant batch reads** - Map.values(cache) is O(1) access, O(N) copy

  This design scales to 10,000+ entities because the coordinator is just
  a mailbox that collects pushed updates. Reading the cache is instant.

  ## Event Flow (Every 100ms Tick)

  ```
  WorldClock
    ├─→ PubSub.broadcast(:tick) ──→ Bus 1, Bus 2, ..., Bus 50 (parallel)
    │                                 ↓
    │                          Each moves independently
    │                                 ↓
    │                          PubSub.broadcast(:position_changed)
    │                                 ↓
    │                          Coordinator (receives & caches)
    │
    └─→ send(Coordinator, :tick_window_start)
              ↓
        Coordinator reads cache (no queries!)
              ↓
        PubSub.broadcast(:entities_updated) ──→ LiveView ──→ Canvas (60fps)
  ```
  """

  use GenServer
  require Logger

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get current entity positions from the coordinator's cache.

  This is the single source of truth for entity positions in the event-driven architecture.
  """
  def get_entities do
    GenServer.call(__MODULE__, :get_entities)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Subscribe to position updates from all entities
    Phoenix.PubSub.subscribe(Ttex.PubSub, "simulation:position_updates")

    state = %{
      # Map of entity_id => %{x, y, type}
      entity_positions:
        Ttex.CityMap.stop_entities()
        |> Map.new(fn entity -> {entity.id, entity} end),
      # Tick tracking (for log correlation only, not metrics)
      tick_count: 0,
      # Timing for health metrics
      last_tick_time: System.monotonic_time(:millisecond),
      # Performance metrics
      updates_per_window: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_entities, _from, state) do
    entities = Map.values(state.entity_positions)
    {:reply, entities, state}
  end

  def handle_info({:tick_window_start, _timestamp}, state) do
    # Calculate tick interval for health metrics
    now = System.monotonic_time(:millisecond)
    tick_interval_ms = now - state.last_tick_time

    # Use telemetry.span for proper start/stop duration measurement
    new_state =
      :telemetry.span(
        [:ttex, :simulation, :tick],
        %{tick_count: state.tick_count + 1},
        fn ->
          # Set log metadata for correlation with telemetry metrics
          tick_num = state.tick_count + 1
          Logger.metadata(tick_count: tick_num, component: :simulation_coordinator)

          # Flush accumulated updates to LiveView (batching for performance)
          # This is a pure read from our cache - NO fetching/querying happens.
          # All position data was pushed to us by entities during this tick window.
          entities = Map.values(state.entity_positions)

          # Broadcast batch to LiveView (10Hz updates, canvas renders at 60fps)
          Phoenix.PubSub.broadcast(
            Ttex.PubSub,
            "simulation:entities",
            {:entities_updated, entities}
          )

          # Update state
          new_state = %{
            state
            | tick_count: state.tick_count + 1,
              last_tick_time: now,
              updates_per_window: 0
          }

          # Emit health and performance metrics
          :telemetry.execute(
            [:ttex, :simulation, :tick, :health],
            %{
              # Health metrics
              tick_interval_ms: tick_interval_ms,
              mailbox_len: :erlang.process_info(self(), :message_queue_len) |> elem(1),
              # Performance metrics
              entity_count: map_size(new_state.entity_positions),
              updates_per_window: state.updates_per_window
            },
            %{}
          )

          # Return {result, stop_metadata} for telemetry.span
          {new_state, %{}}
        end
      )

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:position_changed, entity_id, x, y, type}, state) do
    # Entity pushed a position update - cache it (passive receive, no query)
    entity = %{id: entity_id, x: x, y: y, type: type}

    new_state = %{
      state
      | entity_positions: Map.put(state.entity_positions, entity_id, entity),
        updates_per_window: state.updates_per_window + 1
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:entity_spawned, entity_id, x, y, type}, state) do
    # New entity joined the simulation
    entity = %{id: entity_id, x: x, y: y, type: type}

    new_state = %{
      state
      | entity_positions: Map.put(state.entity_positions, entity_id, entity)
    }

    Logger.debug("Entity spawned",
      entity_id: entity_id,
      position: {x, y},
      type: type,
      total_entities: map_size(new_state.entity_positions)
    )

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:entity_despawned, entity_id}, state) do
    # Entity left the simulation
    new_state = %{
      state
      | entity_positions: Map.delete(state.entity_positions, entity_id)
    }

    Logger.debug("Entity despawned",
      entity_id: entity_id,
      total_entities: map_size(new_state.entity_positions)
    )

    {:noreply, new_state}
  end
end
