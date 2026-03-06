defmodule Ttex.Bus do
  @moduledoc """
  A GenServer representing a bus in the transit simulation.

  Each bus has an ID, position (x, y coordinates), driver name, and bus number.
  """

  use GenServer

  @type t :: %__MODULE__{
          id: String.t(),
          position: {number(), number()},
          driver_name: String.t(),
          bus_number: String.t(),
          destination: {number(), number()} | nil
        }

  defstruct [:id, :position, :driver_name, :bus_number, :destination]

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    position = Keyword.get(opts, :position, {0, 0})
    driver_name = Keyword.get_lazy(opts, :driver_name, &generate_driver_name/0)

    GenServer.start_link(__MODULE__, {id, position, driver_name}, name: via_tuple(id))
  end

  @doc """
  Returns the current position of the bus.

  ## Examples

      iex> {:ok, pid} = Ttex.Bus.start_link(id: "bus-1", position: {5, 10})
      iex> Ttex.Bus.position(pid)
      {5, 10}
  """
  @spec position(GenServer.server() | String.t()) :: {number(), number()}
  def position(bus) when is_pid(bus) or is_atom(bus) do
    GenServer.call(bus, :get_position)
  end

  def position(bus_id) when is_binary(bus_id) do
    GenServer.call(via_tuple(bus_id), :get_position)
  end

  @doc """
  Moves the bus to a new position.

  This is a cast (asynchronous) - returns immediately without waiting
  for the bus to update its position.

  ## Examples

      iex> {:ok, pid} = Ttex.Bus.start_link(id: "bus-1", position: {0, 0})
      iex> Ttex.Bus.move_to(pid, 3, 7)
      :ok
      iex> state = Ttex.Bus.get_state(pid)
      iex> {state.id, state.position}
      {"bus-1", {3, 7}}
  """
  @spec move_to(GenServer.server() | String.t(), number(), number()) :: :ok
  def move_to(bus, x, y) when is_pid(bus) or is_atom(bus) do
    GenServer.cast(bus, {:move_to, x, y})
  end

  def move_to(bus_id, x, y) when is_binary(bus_id) do
    GenServer.cast(via_tuple(bus_id), {:move_to, x, y})
  end

  # Private Helpers

  defp via_tuple(bus_id) do
    {:via, Registry, {Ttex.ProcessRegistry, bus_id}}
  end

  defp generate_driver_name do
    UniqueNamesGenerator.generate([:names, :star_wars], %{style: :capital, separator: " "})
  end

  # Server Callbacks

  @impl true
  def init({id, position, driver_name}) do
    bus_number = self() |> :erlang.pid_to_list() |> to_string()

    state = %__MODULE__{
      id: id,
      position: position,
      driver_name: driver_name,
      bus_number: bus_number,
      destination: random_destination()
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_position, _from, state) do
    {:reply, state.position, state}
  end

  @impl true
  def handle_cast({:move_to, x, y}, state) do
    new_state = %{state | position: {x, y}}
    {:noreply, new_state}
  end

  # Handle tick from World Clock via Coordinator
  @impl true
  def handle_info({:tick, _timestamp}, state) do
    {current_x, current_y} = state.position
    {dest_x, dest_y} = state.destination

    # If at destination, pick new random destination
    new_state =
      if current_x == dest_x and current_y == dest_y do
        %{state | destination: random_destination()}
      else
        # Move one step toward destination (Manhattan distance)
        new_x =
          cond do
            current_x < dest_x -> current_x + 1
            current_x > dest_x -> current_x - 1
            true -> current_x
          end

        new_y =
          cond do
            current_y < dest_y -> current_y + 1
            current_y > dest_y -> current_y - 1
            true -> current_y
          end

        %{state | position: {new_x, new_y}}
      end

    {:noreply, new_state}
  end

  # Private helper for random destination
  defp random_destination do
    {Enum.random(0..9), Enum.random(0..9)}
  end
end
