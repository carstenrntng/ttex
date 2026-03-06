defmodule Ttex.Transit do
  @moduledoc """
  Context module for transit system operations.

  Provides high-level functions for querying buses, citizens, and other
  transit entities for use in LiveViews and other parts of the application.
  """

  require Logger

  @doc """
  Returns all buses as entity maps suitable for LiveView rendering.

  Uses Registry.select for efficient bulk lookup, then queries each bus
  in parallel using Task.async_stream for optimal performance with 10-50+ buses.

  ## Return format

  Returns a list of entity maps with the following structure:

      [%{id: "bus-1", x: 2, y: 3, type: :bus}, ...]

  ## Performance

  - Registry.select: O(N) single ETS scan (< 1ms for 50 entries)
  - Task.async_stream: Parallel GenServer calls with back-pressure
    - 10 buses @ 1ms each ≈ 1-2ms total
    - 50 buses @ 1ms each ≈ 2-5ms total

  ## Error handling

  Dead or unresponsive processes are logged and skipped. The function
  returns all successfully queried buses without failing.

  ## Examples

      iex> Ttex.Transit.list_all_buses_as_entities()
      [
        %{id: "bus-1", x: 0, y: 0, type: :bus},
        %{id: "bus-2", x: 5, y: 3, type: :bus}
      ]
  """
  @spec list_all_buses_as_entities() :: [map()]
  def list_all_buses_as_entities do
    # Step 1: Bulk lookup - get ALL bus PIDs + IDs from Registry in one call
    # Match spec: [{match_pattern, guards, return_value}]
    Registry.select(Ttex.ProcessRegistry, [
      {
        # Match: key=$1 (bus_id), pid=$2, value=ignore
        {:"$1", :"$2", :_},
        # Guard: only match string keys (bus IDs start with "bus-")
        [{:is_binary, :"$1"}],
        # Return: {bus_id, pid} tuples
        [{{:"$1", :"$2"}}]
      }
    ])
    # Step 2: Parallel query with back-pressure control
    |> Task.async_stream(
      fn {bus_id, pid} ->
        # Query position from bus GenServer
        {x, y} = GenServer.call(pid, :get_position, 5000)
        %{id: bus_id, x: x, y: y, type: :bus}
      end,
      # CRITICAL: timeout: :infinity prevents premature termination
      # max_concurrency: limits parallel calls (default: System.schedulers_online * 2)
      timeout: :infinity,
      max_concurrency: 50,
      on_timeout: :kill_task
    )
    # Step 3: Collect results, handling failures gracefully
    |> Enum.reduce([], fn
      {:ok, entity}, acc ->
        [entity | acc]

      {:exit, reason}, acc ->
        Logger.warning("Bus query failed: #{inspect(reason)}")
        acc
    end)
  end
end
