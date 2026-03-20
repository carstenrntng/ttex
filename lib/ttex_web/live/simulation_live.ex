defmodule TtexWeb.SimulationLive do
  @moduledoc """
  Workshop starter: A minimal LiveView that renders entities on a canvas.

  ## What is a Socket?

  The `socket` is a server-side struct (`Phoenix.LiveView.Socket`) that holds
  the state of your LiveView process. Think of it as the "this" or "self" of
  your LiveView - it's passed through every callback and contains everything
  needed to render and update the UI.

  ### Key Concepts

  **Socket Assigns (`socket.assigns`)**
  - All your application data lives here
  - Access in LiveView code: `socket.assigns.running`
  - Access in templates: `@running`
  - Set with `assign(socket, :key, value)` or `assign(socket, key: value)`

  **Socket Lifecycle**
  1. `mount/3` called twice:
     - First: Initial HTTP request (static render)
     - Second: WebSocket connection established
     - Use `connected?(socket)` to detect WebSocket phase
  2. `handle_event/3` processes client interactions (clicks, form submits)
  3. `handle_info/2` processes Elixir messages (from GenServers, timers, PubSub)
  4. After each callback, LiveView computes diffs and pushes to client

  **Common Socket Operations**
  - `assign(socket, key: value)` - Set one or more assigns
  - `update(socket, :key, fn old -> new end)` - Update assign with function
  - `push_event(socket, "event", %{data})` - Send data to JavaScript hooks
  - `connected?(socket)` - Check if WebSocket connected (true on second mount)

  ### Workshop Note

  As you build GenServers for buses and citizens, you'll use sockets to:
  - Store simulation state (entity positions, counts, active processes)
  - Receive updates from GenServers via `handle_info/2`
  - Push real-time updates to the canvas via `push_event/3`
  - Manage subscriptions to PubSub topics for entity broadcasts
  """
  use TtexWeb, :live_view

  # Called when the LiveView first connects
  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to coordinator entity updates when WebSocket connects
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Ttex.PubSub, "simulation:entities")
    end

    socket =
      socket
      # Track if demo is active
      |> assign(:running, false)
      # Store entity list for reconnection
      |> assign(:entities, [])

    {:ok, socket}
  end

  # Handle "Start Demo" button click
  @impl true
  def handle_event("start_demo", _params, socket) do
    # Get initial entities from coordinator (single source of truth)
    entities = Ttex.SimulationCoordinator.get_entities()

    # Start the world clock
    Ttex.WorldClock.start_ticking()

    socket =
      socket
      |> assign(:running, true)
      |> assign(:entities, entities)
      # push_event sends data to JavaScript hook
      |> push_event("entities", %{entities: entities})

    {:noreply, socket}
  end

  # Handle "Clear" button click
  @impl true
  def handle_event("clear", _params, socket) do
    # Stop the world clock
    Ttex.WorldClock.stop_ticking()

    socket =
      socket
      |> assign(:running, false)
      |> assign(:entities, [])
      # Clear the canvas by sending empty list
      |> push_event("entities", %{entities: []})

    {:noreply, socket}
  end

  # Handle batch entity updates from SimulationCoordinator
  @impl true
  def handle_info({:entities_updated, entities}, socket) do
    socket =
      socket
      |> assign(:entities, entities)
      # Push updated entities to canvas
      |> push_event("entities", %{entities: entities})

    {:noreply, socket}
  end

  # Renders the LiveView template
  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Use custom fullwidth layout instead of Layouts.app to span viewport --%>
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <Layouts.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-8 sm:px-6 lg:px-8">
      <div class="mb-4">
        <%!-- Button toggles based on @running state --%>
        <%= if @running do %>
          <button
            phx-click="clear"
            class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
          >
            Clear
          </button>
        <% else %>
          <button
            phx-click="start_demo"
            class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          >
            Start Demo
          </button>
        <% end %>
      </div>

      <div class="mb-4 rounded-xl border border-base-300 bg-base-100 px-4 py-3 text-sm shadow-sm">
        <p class="font-medium text-base-content">Canvas controls</p>
        <p class="text-base-content/70">
          Scroll or +/- to zoom, drag to pan, double-click or fit to reset to the full grid view.
        </p>
      </div>

      <div class="flex flex-col lg:flex-row gap-6">
        <%!-- Canvas spans full available width --%>
        <div
          id="sim-canvas-container"
          phx-hook="SimulationCanvas"
          phx-update="ignore"
          class="bg-gray-50 flex-1 flex items-center justify-center"
          data-grid-rows={Ttex.CityMap.grid_rows()}
          data-grid-cols={Ttex.CityMap.grid_cols()}
        >
          <%!-- Canvas dimensions set by JavaScript to maintain square aspect ratio --%>
          <%!-- Grid dimensions and cell size are calculated dynamically --%>
          <canvas
            id="sim-canvas"
            class="block"
          />
        </div>

        <%!-- Legend Panel --%>
        <div class="card bg-base-200 w-full lg:w-64 shrink-0 h-fit">
          <div class="card-body">
            <h2 class="card-title text-lg">Legend</h2>
            <ul class="space-y-3">
              <li class="flex items-center gap-3">
                <div class="w-7 h-4 rounded-sm bg-blue-600 border border-blue-900 relative overflow-hidden">
                  <div class="absolute left-1 right-1 top-0.5 h-1.5 rounded-[2px] bg-blue-100"></div>
                  <div class="absolute left-0 right-0 bottom-0 h-1 bg-blue-900"></div>
                </div>
                <span>Bus</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="w-6 h-6 rounded-full bg-orange-500 flex items-center justify-center">
                  <span class="text-white text-xs font-bold">N</span>
                </div>
                <div>
                  <p>Citizen / Crowd</p>
                  <p class="text-xs text-base-content/70">(Number shown when multiple)</p>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="relative h-6 w-6">
                  <div class="absolute inset-0 rounded-full bg-yellow-400">
                    <div class="absolute inset-[1.5px] rounded-full border-[1.5px] border-lime-600">
                    </div>
                    <div class="absolute inset-0 flex items-center justify-center text-[11px] font-black leading-none text-lime-900">
                      H
                    </div>
                  </div>
                </div>
                <span>Stop</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </main>

    <Layouts.flash_group flash={@flash} />
    """
  end

  # Helper for future use: Broadcast entity updates via PubSub
  # When you create GenServers, they can call this to notify all LiveViews
  def broadcast_entities(entities) do
    Phoenix.PubSub.broadcast(
      Ttex.PubSub,
      "simulation:entities",
      {:entities_updated, entities}
    )
  end
end
