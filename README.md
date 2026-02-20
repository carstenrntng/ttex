# Transport Tycoon - Elixir Edition

City transit simulation: ~50 buses and ~5,000 citizens as OTP processes, visualized with Phoenix LiveView.

## Prerequisites

### Required

- **Elixir 1.17+** with Erlang/OTP 26+ ([installation guide](https://elixir-lang.org/install.html))
- **SQLite** (included with most systems)
- **Node.js 22+** (for asset compilation via esbuild/tailwind)

### Optional

- **OpenCode** (AI-assisted development) - [https://opencode.dev](https://opencode.dev)
- **GitHub CLI (`gh`)** (used by OpenCode for GitHub operations)

### Verify Installation

```bash
elixir --version  # Should show 1.17+ and OTP 26+
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
