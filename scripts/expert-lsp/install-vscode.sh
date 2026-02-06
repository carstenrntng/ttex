#!/bin/sh
set -e

# Default values
EXPERT_PATH="${HOME}/.local/bin/expert"
YES_FLAG=0

# Help text
show_help() {
	cat <<EOF
Usage: install-vscode.sh [OPTIONS]

Install Expert LSP extension for Visual Studio Code.

OPTIONS:
  --help              Show this help message and exit
  --expert-path PATH  Specify where Expert binary is installed
                      (default: ~/.local/bin/expert)
  --yes               Non-interactive mode, skip confirmations

REQUIREMENTS:
  - VSCode CLI (code command)

EXAMPLES:
  install-vscode.sh
  install-vscode.sh --expert-path /usr/local/bin/expert
  install-vscode.sh --yes

EOF
}

# Parse arguments
while [ $# -gt 0 ]; do
	case "$1" in
	--help)
		show_help
		exit 0
		;;
	--expert-path)
		if [ -z "$2" ]; then
			echo "Error: --expert-path requires a PATH argument" >&2
			exit 1
		fi
		EXPERT_PATH="$2"
		shift 2
		;;
	--yes)
		YES_FLAG=1
		shift
		;;
	*)
		echo "Error: Unknown option: $1" >&2
		echo "Run with --help for usage information" >&2
		exit 1
		;;
	esac
done

# Check for required dependencies
if ! command -v code >/dev/null 2>&1; then
	echo "Error: VSCode CLI 'code' command not found" >&2
	echo "Please install VSCode and ensure 'code' is in your PATH" >&2
	exit 1
fi

# Install extension
echo "Installing Expert LSP extension from VSCode Marketplace..."
if ! code --install-extension ExpertLSP.expert --force; then
	echo "Error: Failed to install extension" >&2
	exit 1
fi

echo "Extension installed successfully!"

# Detect VSCode settings file location based on OS
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
Darwin)
	SETTINGS_DIR="${HOME}/Library/Application Support/Code/User"
	;;
Linux)
	SETTINGS_DIR="${HOME}/.config/Code/User"
	;;
*)
	echo "Warning: Unsupported OS type: $OS_TYPE" >&2
	echo "Skipping auto-configuration. Please manually set 'expert.server.releasePathOverride' in VSCode settings." >&2
	exit 0
	;;
esac

SETTINGS_FILE="${SETTINGS_DIR}/settings.json"

# Warn if Expert binary not at expected path
if [ ! -f "$EXPERT_PATH" ] && [ ! -x "$EXPERT_PATH" ]; then
	echo "Warning: Expert binary not found at: $EXPERT_PATH" >&2
	echo "The extension will be configured, but you may need to install Expert or adjust the path." >&2
fi

# Prompt for confirmation if not in yes mode
if [ "$YES_FLAG" -eq 0 ]; then
	printf "Configure VSCode to use Expert at '%s'? [Y/n] " "$EXPERT_PATH"
	read -r REPLY
	case "$REPLY" in
	[nN] | [nN][oO])
		echo "Skipping configuration. Extension installed but not configured."
		exit 0
		;;
	esac
fi

# Create settings directory if missing
if [ ! -d "$SETTINGS_DIR" ]; then
	echo "Creating settings directory: $SETTINGS_DIR"
	mkdir -p "$SETTINGS_DIR"
fi

# Create settings file with empty object if missing
if [ ! -f "$SETTINGS_FILE" ]; then
	echo "Creating settings file: $SETTINGS_FILE"
	echo "{}" >"$SETTINGS_FILE"
fi

# Backup settings file
cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
echo "Settings backed up to: ${SETTINGS_FILE}.bak"

# Add or update expert.server.releasePathOverride setting
if grep -q '"expert.server.releasePathOverride"' "$SETTINGS_FILE"; then
	echo "Updating existing Expert LSP configuration..."
	# Use temp file approach to follow symlinks
	sed 's|"expert.server.releasePathOverride":[^,}]*|"expert.server.releasePathOverride": "'"$EXPERT_PATH"'"|' "$SETTINGS_FILE" >"${SETTINGS_FILE}.tmp"
	cat "${SETTINGS_FILE}.tmp" >"$SETTINGS_FILE"
	rm -f "${SETTINGS_FILE}.tmp"
else
	echo "Adding Expert LSP configuration..."
	if grep -q '^{}$' "$SETTINGS_FILE"; then
		cat >"$SETTINGS_FILE" <<EOF
{
  "expert.server.releasePathOverride": "$EXPERT_PATH"
}
EOF
	else
		# Insert before final closing brace - use temp file to follow symlinks
		sed 's|}[[:space:]]*$|,\n  "expert.server.releasePathOverride": "'"$EXPERT_PATH"'"\n}|' "$SETTINGS_FILE" >"${SETTINGS_FILE}.tmp"
		cat "${SETTINGS_FILE}.tmp" >"$SETTINGS_FILE"
		rm -f "${SETTINGS_FILE}.tmp"
	fi
fi

echo ""
echo "✓ Expert LSP extension installed and configured!"
echo "✓ Settings configured at: $SETTINGS_FILE"
echo "✓ Expert path: $EXPERT_PATH"
echo ""
echo "Restart VSCode to activate the extension."
