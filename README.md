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
```
