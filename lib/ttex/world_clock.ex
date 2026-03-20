defmodule Ttex.WorldClock do
  @moduledoc """
  World Clock GenServer that drives the event-driven simulation.

  The clock runs at a configurable interval (default 100ms) and performs TWO actions:

  1. **Broadcasts ticks to all entities** (buses, citizens) via PubSub
     - Each entity independently advances its state and pushes position updates

  2. **Signals coordinator to flush batched updates** to LiveView
     - Coordinator collects position changes during the tick window
     - When signaled, it broadcasts the batch to LiveView for rendering

  This two-phase approach enables:
  - Parallel entity processing (scales to 10,000+ entities)
  - Batched UI updates (10Hz data, 60fps rendering)
  - No polling or querying (pure event-driven)
  """

  use GenServer
  require Logger

  @default_interval_ms 100

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Start sending tick messages.
  """
  def start_ticking do
    GenServer.cast(__MODULE__, :start)
  end

  @doc """
  Stop sending tick messages.
  """
  def stop_ticking do
    GenServer.cast(__MODULE__, :stop)
  end

  @doc """
  Get current tick interval in milliseconds.
  """
  def get_interval do
    GenServer.call(__MODULE__, :get_interval)
  end

  @doc """
  Set tick interval in milliseconds.
  """
  def set_interval(ms) when is_integer(ms) and ms > 0 do
    GenServer.cast(__MODULE__, {:set_interval, ms})
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval_ms)

    state = %{
      interval_ms: interval_ms,
      running: false,
      timer_ref: nil,
      tick_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:start, %{running: true} = state) do
    # Already running
    {:noreply, state}
  end

  def handle_cast(:start, %{running: false} = state) do
    timer_ref = schedule_tick(state.interval_ms)
    Logger.info("World Clock started (interval: #{state.interval_ms}ms)")
    {:noreply, %{state | running: true, timer_ref: timer_ref}}
  end

  def handle_cast(:stop, %{running: false} = state) do
    # Already stopped
    {:noreply, state}
  end

  def handle_cast(:stop, %{running: true, timer_ref: timer_ref} = state) do
    if timer_ref, do: Process.cancel_timer(timer_ref)
    Logger.info("World Clock stopped (total ticks: #{state.tick_count})")
    {:noreply, %{state | running: false, timer_ref: nil}}
  end

  def handle_cast({:set_interval, ms}, state) do
    # If running, restart with new interval
    new_state =
      if state.running do
        if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
        timer_ref = schedule_tick(ms)
        %{state | interval_ms: ms, timer_ref: timer_ref}
      else
        %{state | interval_ms: ms}
      end

    Logger.info("World Clock interval changed to #{ms}ms")
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_interval, _from, state) do
    {:reply, state.interval_ms, state}
  end

  @impl true
  def handle_info(:tick, %{running: true} = state) do
    timestamp = System.monotonic_time(:millisecond)

    # PHASE 1: Tell all entities to advance their simulation state
    # Each bus/citizen receives this, moves independently, and PUSHES position updates
    # to the coordinator. No polling/querying happens - pure event-driven.
    Phoenix.PubSub.broadcast(
      Ttex.PubSub,
      "simulation:tick",
      {:tick, timestamp}
    )

    # PHASE 2: Tell coordinator to flush the batch to LiveView
    # By now, entities have pushed their position changes to the coordinator.
    # This signals "time window is over, send accumulated updates to UI now".
    # Coordinator never fetches/queries - just reads from its own cache.
    send(Ttex.SimulationCoordinator, {:tick_window_start, timestamp})

    # Schedule next tick
    timer_ref = schedule_tick(state.interval_ms)
    {:noreply, %{state | timer_ref: timer_ref, tick_count: state.tick_count + 1}}
  end

  def handle_info(:tick, %{running: false} = state) do
    # Ignore ticks when not running (stale timer messages)
    {:noreply, state}
  end

  # Private Helpers

  defp schedule_tick(interval_ms) do
    Process.send_after(self(), :tick, interval_ms)
  end
end
