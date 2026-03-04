# Transport Tycoon - Elixir Edition

City transit simulation: ~50 buses and ~5,000 citizens as OTP processes, visualized with Phoenix LiveView.

## Prerequisites

### Required

- **Elixir 1.19+** with Erlang/OTP 28+ ([installation guide](https://elixir-lang.org/install.html))
- **SQLite** (included with most systems)
- **Node.js 22+** (for asset compilation via esbuild/tailwind)

### Using asdf (Recommended)

If you use [asdf](https://asdf-vm.com/), first add the required plugins:

```bash
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
```

Then install the correct versions:

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
node --version    # Should show 24+
```

## Setup

```bash
mix setup
iex -S mix phx.server
```

Visit [`http://localhost:4000/starter-sim`](http://localhost:4000/starter-sim)

## Development

```bash
mix precommit  # Run before committing (format, credo, dialyzer, test)
mix test       # Run tests
```

## Using TNG Skainet Models (Optional)

This repo includes a pre-configured OpenCode profile for the TNG internal Skainet cluster.

**Quick start:**

```bash
OPENCODE_CONFIG=./opencode.skainet.jsonc opencode
```

On first use, run `/connect` inside OpenCode and select the Skainet provider(s) to authenticate.

**Tip:** Add a shell alias for convenience:

```bash
# Add to your ~/.bashrc, ~/.zshrc, etc.
alias oc-tng='OPENCODE_CONFIG=./opencode.skainet.jsonc opencode'
```

This merges with your personal `~/.config/opencode/opencode.json` — your themes, keybinds, and permissions are preserved. Only the provider and model defaults are overridden.

**Available models:**

| Provider         | Model                     | Notes                       |
| ---------------- | ------------------------- | --------------------------- |
| Skainet External | GLM 5 FP8 (default)       | 200K context                |
| Skainet          | Qwen3 Coder 480B          | Strong coding model         |
| Skainet          | DeepSeek TNG R1T2 Chimera | Reasoning model             |
| Skainet          | GPT OSS 120b              | Reasoning effort variants   |
| Skainet          | GLM 4.7 FP8 / Flash       | General purpose             |
| Skainet          | Qwen3 VL 235B             | Vision + text               |
| Skainet          | Mistral Small 3.2 24B     | Lightweight, vision capable |

Switch models anytime with `/models` inside OpenCode.

## Excalidraw Diagramming (Optional)

AI-assisted diagramming via [Excalidraw MCP](https://github.com/yctimlin/mcp_excalidraw) (requires OpenCode + Docker).

**Quick start:**

```bash
mix excalidraw.start  # Starts canvas at localhost:3000
```

Ask OpenCode to create diagrams (e.g., "Draw the OTP supervision tree"). Diagrams appear in real-time in your browser. Exported diagrams (`.excalidraw`, PNG) are saved to the repo root.

```bash
mix excalidraw.stop  # Stop canvas when done

# Info Dump

- name generation example: `UniqueNamesGenerator.generate([:names, :star_wars], %{style: :capital, separator: " "})`
```

## Tidewave MCP: Your Phoenix Development Superpower (Optional)

[Tidewave MCP](https://github.com/tidewave-ai/tidewave_phoenix) gives you live inspection of your running Phoenix application through OpenCode. Instead of switching between terminal windows, IEx sessions, and browser tabs, just ask OpenCode natural language questions about your database, schemas, functions, and logs.

### Why Use Tidewave?

**Traditional debugging workflow:**

```bash
# Check database state
sqlite3 ttex_dev.db "SELECT * FROM buses WHERE id = 42"

# Test a function
iex -S mix phx.server
iex> Ttex.Transit.assign_citizen_to_bus(citizen_123, bus_42)

# Look up docs
# Open browser → hexdocs.pm → search → hope version matches

# Check logs
# Scroll terminal output or grep log files
```

**With Tidewave + OpenCode:**

Just ask:

- *"Show me bus #42 from the database"*
- *"Run `Ttex.Transit.assign_citizen_to_bus(citizen_123, bus_42)` and show the result"*
- *"How do I use `Ecto.Query.join/5` in this project?"* ← Gets docs for YOUR exact Ecto version
- *"What are the recent application errors?"*

OpenCode answers instantly using your running dev server.

### Real Workshop Benefits

**🔍 Debug GenServers without breaking flow**

Instead of opening IEx and manually querying, ask OpenCode:
> *"Is bus #42's position updating in the database?"*

OpenCode runs the query, shows results, and helps diagnose issues—all in one response.

**🗺️ Explore schemas instantly**

> *"Which Ecto schemas have a `user_id` field?"*

Get an instant list with file paths. No `grep` archaeology needed.

**⚡ Test functions in context**

> *"Run `Ttex.Transit.list_active_routes()` and show the results"*

OpenCode executes it in your running application and shows the return value. Perfect for quick validation without writing test boilerplate.

**📚 Version-matched documentation**

> *"Show me the docs for `Ecto.Query.from/2` in this project"*

Gets documentation for the exact Ecto version in your `mix.lock`—no version mismatches.

**🪵 Instant log access**

> *"Show me errors from the last 5 minutes"*

OpenCode fetches buffered application logs without scrolling terminal output.

### How It Works

Tidewave runs a TCP server inside your Phoenix application (dev mode only). When you start the dev server with `mix phx.server`, Tidewave automatically starts on localhost:4000. OpenCode connects to it and can:

- Execute SQL queries against your SQLite database
- List and inspect Ecto schemas
- Evaluate Elixir code in the running application (like `IEx.pry` but non-blocking)
- Fetch documentation for your exact dependency versions
- Read buffered application logs

**Zero setup required**—it's already configured in this workshop repo.

### Quick Start

1. Start the dev server: `mix phx.server`
2. Open OpenCode in a separate terminal
3. Ask questions about your running application!

Examples:

- *"Show me all buses in the database"*
- *"List all Ecto schemas with their file locations"*
- *"Run `Ttex.Repo.aggregate(Ttex.Citizen, :count)` and show how many citizens exist"*
- *"What does `Phoenix.PubSub.broadcast/3` do in this project's Phoenix version?"*

Tidewave makes learning Phoenix and OTP faster by keeping you in flow—no more context switching between tools.
