defmodule Ttex.WorldClock do
  @moduledoc """
  World Clock GenServer that sends periodic tick messages to the Simulation Coordinator.

  The clock runs at a configurable interval (default 100ms) and sends
  `{:tick, timestamp}` messages to drive the simulation forward.
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

    # Send tick to coordinator
    send(Ttex.SimulationCoordinator, {:tick, timestamp})

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
