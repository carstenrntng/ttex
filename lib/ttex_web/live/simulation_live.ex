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
    entities = demo_entities()

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
    socket =
      socket
      |> assign(:running, false)
      |> assign(:entities, [])
      # Clear the canvas by sending empty list
      |> push_event("entities", %{entities: []})

    {:noreply, socket}
  end

  # Renders the LiveView template
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-8">
        <h1 class="text-3xl font-bold mb-4">Simulation</h1>

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

        <div class="flex flex-col lg:flex-row gap-6">
          <%!-- Canvas --%>
          <div
            id="sim-canvas-container"
            phx-hook=".SimCanvas"
            phx-update="ignore"
            class="bg-gray-50"
          >
            <%!-- HTML5 Canvas: 800x800 pixels, 10x10 grid (80px cells) --%>
            <canvas
              id="sim-canvas"
              width="800"
              height="800"
              class="block"
            />
            <%!-- Colocated JS Hook: Renders entities on canvas --%>
            <script :type={Phoenix.LiveView.ColocatedHook} name=".SimCanvas">
              export default {
                // Called when the hook attaches to the DOM
                mounted() {
                  this.canvas = document.getElementById("sim-canvas");
                  this.ctx = this.canvas.getContext("2d");
                  this.drawGrid();

                  // Listen for entity updates from the server
                  this.handleEvent("entities", data => {
                    this.drawEntities(data.entities);
                  });
                },

                // Draw 10x10 grid (80px cells)
                drawGrid() {
                  const canvas = this.canvas;
                  const ctx = this.ctx;
                  const CELL_SIZE = 80;
                  const SIZE = 800;

                  // Handle devicePixelRatio for crisp rendering on high-DPI displays
                  const dpr = window.devicePixelRatio || 1;
                  canvas.style.width = `${SIZE}px`;
                  canvas.style.height = `${SIZE}px`;
                  canvas.width = Math.round(SIZE * dpr);
                  canvas.height = Math.round(SIZE * dpr);

                  // Scale context to match DPR
                  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
                  ctx.clearRect(0, 0, SIZE, SIZE);

                  ctx.strokeStyle = "#ccc";
                  ctx.lineWidth = 1;

                  // Draw all 11 lines (including boundaries) at half-pixel positions
                  // for crisp 1px lines. Boundaries at 0.5 and 799.5 to avoid clipping.
                  const boundary0 = 0.5;
                  const boundary1 = SIZE - 0.5;

                  for (let i = 0; i <= 10; i++) {
                    const p =
                      i === 0 ? boundary0 :
                      i === 10 ? boundary1 :
                      i * CELL_SIZE + 0.5;

                    // Vertical line
                    ctx.beginPath();
                    ctx.moveTo(p, 0);
                    ctx.lineTo(p, SIZE);
                    ctx.stroke();

                    // Horizontal line
                    ctx.beginPath();
                    ctx.moveTo(0, p);
                    ctx.lineTo(SIZE, p);
                    ctx.stroke();
                  }
                },

              // Draw all entities on canvas
              drawEntities(entities) {
                const ctx = this.ctx;
                const CELL_SIZE = 80;
                const OFFSET = 40;  // Center entities in cells

                // Clear and redraw grid
                ctx.clearRect(0, 0, 800, 800);
                this.drawGrid();

                const citizens = entities.filter(e => e.type === "citizen");
                const otherEntities = entities.filter(e => e.type !== "citizen");

                // Aggregate citizens by position
                const citizenCrowds = new Map();
                citizens.forEach(c => {
                  const key = `${c.x},${c.y}`;
                  if (!citizenCrowds.has(key)) {
                    citizenCrowds.set(key, { x: c.x, y: c.y, count: 0 });
                  }
                  citizenCrowds.get(key).count++;
                });

                // Draw buses and stops
                otherEntities.forEach(e => {
                  const px = e.x * CELL_SIZE + OFFSET;
                  const py = e.y * CELL_SIZE + OFFSET;

                  if (e.type === "stop") {
                    ctx.fillStyle = "#000000";
                    ctx.beginPath();
                    ctx.arc(px, py, 15, 0, 2 * Math.PI);
                    ctx.fill();
                  } else if (e.type === "bus") {
                    ctx.fillStyle = "#0000ff";
                    ctx.fillRect(px - 20, py - 12.5, 40, 25);
                  }
                });

                // Draw citizens and crowds
                citizenCrowds.forEach(crowd => {
                  const px = crowd.x * CELL_SIZE + OFFSET;
                  const py = crowd.y * CELL_SIZE + OFFSET;

                  if (crowd.count === 1) {
                    // Single citizen
                    ctx.fillStyle = "#ff8c00";
                    ctx.beginPath();
                    ctx.arc(px, py, 8, 0, 2 * Math.PI);
                    ctx.fill();
                  } else {
                    // Crowd of citizens
                    const radius = Math.min(8 + Math.log(crowd.count) * 2, 20);
                    ctx.fillStyle = "#ff8c00";
                    ctx.beginPath();
                    ctx.arc(px, py, radius, 0, 2 * Math.PI);
                    ctx.fill();

                    // Draw count text
                    const text = crowd.count.toString();
                    ctx.font = "bold 14px sans-serif";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";

                    // Outline for legibility
                    ctx.strokeStyle = "#000";
                    ctx.lineWidth = 3;
                    ctx.strokeText(text, px, py);

                    // Fill text
                    ctx.fillStyle = "#fff";
                    ctx.fillText(text, px, py);
                  }
                });
              }
              }
            </script>
          </div>

          <%!-- Legend Panel --%>
          <div class="card bg-base-200 w-full lg:w-64 shrink-0 h-fit">
            <div class="card-body">
              <h2 class="card-title text-lg">Legend</h2>
              <ul class="space-y-3">
                <li class="flex items-center gap-3">
                  <div class="w-6 h-4 rounded-sm bg-blue-500"></div>
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
                  <div class="w-6 h-6 rounded-full bg-black"></div>
                  <span>Stop</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Demo data: Replace this with real GenServer state!
  defp demo_entities do
    # Entities use grid coordinates (0-9), not pixels
    # Format: %{id: string, x: int, y: int, type: :bus | :citizen | :stop}
    [
      # Buses
      %{id: "bus-1", x: 2, y: 3, type: :bus},
      %{id: "bus-2", x: 7, y: 5, type: :bus},
      %{id: "bus-3", x: 4, y: 8, type: :bus},
      # Stops
      %{id: "stop-1", x: 0, y: 0, type: :stop},
      %{id: "stop-2", x: 9, y: 9, type: :stop},
      # Scattered Citizens
      %{id: "citizen-1", x: 1, y: 8, type: :citizen},
      %{id: "citizen-2", x: 8, y: 1, type: :citizen},
      # Crowd of 4 at (2, 2)
      %{id: "citizen-3", x: 2, y: 2, type: :citizen},
      %{id: "citizen-4", x: 2, y: 2, type: :citizen},
      %{id: "citizen-5", x: 2, y: 2, type: :citizen},
      %{id: "citizen-6", x: 2, y: 2, type: :citizen},
      # Crowd of 2 at (5, 5)
      %{id: "citizen-7", x: 5, y: 5, type: :citizen},
      %{id: "citizen-8", x: 5, y: 5, type: :citizen},
      # Crowd of 6 at (7, 7)
      %{id: "citizen-9", x: 7, y: 7, type: :citizen},
      %{id: "citizen-10", x: 7, y: 7, type: :citizen},
      %{id: "citizen-11", x: 7, y: 7, type: :citizen},
      %{id: "citizen-12", x: 7, y: 7, type: :citizen},
      %{id: "citizen-13", x: 7, y: 7, type: :citizen},
      %{id: "citizen-14", x: 7, y: 7, type: :citizen}
    ]
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
