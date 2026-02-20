# Transport Tycoon - Elixir Edition

City transit simulation: ~50 buses and ~5,000 citizens as OTP processes, visualized with Phoenix LiveView.

## Prerequisites

### Required

- **Elixir 1.19+** with Erlang/OTP 28+ ([installation guide](https://elixir-lang.org/install.html))
- **SQLite** (included with most systems)
- **Node.js 22+** (for asset compilation via esbuild/tailwind)

### Using asdf (Recommended)

If you use [asdf](https://asdf-vm.com/), run this in the repo root to install the correct versions:

```bash
asdf install
```

This reads `.tool-versions` and installs Erlang 28.3.1 and Elixir 1.19.5-otp-28.

### Optional

- **OpenCode** (AI-assisted development) - [https://opencode.dev](https://opencode.dev)
- **GitHub CLI (`gh`)** (used by OpenCode for GitHub operations)

### Verify Installation

```bash
elixir --version  # Should show 1.19+ and OTP 28+
node --version    # Should show 22+
```

## Setup

```bash
mix setup
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000)

## Development

```bash
mix precommit  # Run before committing (format, credo, dialyzer, test)
mix test       # Run tests
```

## Excalidraw Diagramming (Optional)

AI-assisted diagramming via [Excalidraw MCP](https://github.com/yctimlin/mcp_excalidraw) (requires OpenCode + Docker).

**Quick start:**

```bash
mix excalidraw.start  # Starts canvas at localhost:3000
```

Ask OpenCode to create diagrams (e.g., "Draw the OTP supervision tree"). Diagrams appear in real-time in your browser. Exported diagrams (`.excalidraw`, PNG) are saved to the repo root.

```bash
mix excalidraw.stop  # Stop canvas when done
```
