defmodule PlaygroundEx.GenServerSample do
  # Demo in REPL:
  # recompile
  # {:ok, pid} = GenServer.start_link(PlaygroundEx.GenServerSample, %{x: 0, y: 0})
  # GenServer.call pid, :get_position
  # PlaygroundEx.GenServerSample.position(pid)
  # PlaygroundEx.GenServerSample.move_to(pid, %{x: 10, y: 20})
  # PlaygroundEx.GenServerSample.crash(pid)

  @moduledoc false

  # 1: use GenServer behaviour
  use GenServer

  # 5
  require Logger

  # 3: api (client) functions for convenience
  def position(pid) do
    GenServer.call(pid, :get_position)
  end

  # 5
  def crash(pid) do
    GenServer.stop(pid, {:shutdown, :crash})
  end

  # 4: cast example (fire-and-forget)
  def move_to(pid, new_position) when is_map(new_position) do
    GenServer.cast(pid, {:move_to, new_position})
  end

  # Implement Callbacks

  # 1: essential
  @impl true
  def init(state) when is_map(state) do
    {:ok, state}
  end

  # 2: how to show the current state
  @impl true
  def handle_call(:get_position, _from, state) when is_map(state) do
    return_value = state
    new_state = state

    {:reply, return_value, new_state}
  end

  # 4: sample for cast
  @impl true
  def handle_cast({:move_to, new_position}, _state) when is_map(new_position) do
    Logger.info("🚌 Moving to new position: #{inspect(new_position)}")
    {:noreply, new_position}
  end

  # 5: cleanup
  # https://hexdocs.pm/elixir/GenServer.html#stop/3
  # https://hexdocs.pm/elixir/GenServer.html#c:terminate/2
  @impl true
  def terminate({:shutdown, :crash}, _state) do
    Logger.error("🚌 Aaaaaaah... 💥")
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end
end
