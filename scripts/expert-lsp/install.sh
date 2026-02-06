#!/bin/sh
set -e

# Default values
INSTALL_PATH="${HOME}/.local/bin"
YES_FLAG=0

# Usage information
show_help() {
	cat <<EOF
Usage: install.sh [OPTIONS]

Install the expert language server from GitHub releases.

OPTIONS:
  --help            Show this help message and exit
  --path PATH       Custom installation directory (default: ~/.local/bin)
  --yes             Non-interactive mode (skip confirmation prompts)

EXAMPLES:
  install.sh
  install.sh --path /usr/local/bin
  install.sh --yes --path ~/.local/bin

EOF
}

# Parse command line arguments
while [ $# -gt 0 ]; do
	case "$1" in
	--help)
		show_help
		exit 0
		;;
	--path)
		if [ -z "$2" ]; then
			echo "Error: --path requires a directory path" >&2
			exit 1
		fi
		INSTALL_PATH="$2"
		shift 2
		;;
	--yes)
		YES_FLAG=1
		shift
		;;
	*)
		echo "Error: Unknown option: $1" >&2
		echo "Use --help for usage information" >&2
		exit 1
		;;
	esac
done

# Detect OS
detect_os() {
	os_name=$(uname -s)
	case "$os_name" in
	Darwin)
		echo "darwin"
		;;
	Linux)
		echo "linux"
		;;
	*)
		echo "Error: Unsupported OS: $os_name" >&2
		exit 1
		;;
	esac
}

# Detect architecture
detect_arch() {
	arch_name=$(uname -m)
	case "$arch_name" in
	x86_64)
		echo "amd64"
		;;
	aarch64 | arm64)
		echo "arm64"
		;;
	*)
		echo "Error: Unsupported architecture: $arch_name" >&2
		exit 1
		;;
	esac
}

# Check required dependencies
check_dependencies() {
	if ! command -v curl >/dev/null 2>&1; then
		echo "Error: curl is required but not found" >&2
		echo "Please install curl and try again" >&2
		exit 1
	fi

	# Check for sha256sum (Linux) or shasum (macOS)
	if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
		echo "Error: sha256sum or shasum is required but not found" >&2
		echo "Please install coreutils (Linux) or use macOS built-in shasum" >&2
		exit 1
	fi
}

# Main installation logic
main() {
	echo "Expert LSP Installer"
	echo "===================="
	echo ""

	# Check dependencies
	check_dependencies

	# Detect system
	OS=$(detect_os)
	ARCH=$(detect_arch)
	echo "Detected system: $OS/$ARCH"

	# Construct binary name
	BINARY_NAME="expert_${OS}_${ARCH}"
	echo "Binary name: $BINARY_NAME"

	# GitHub release URLs
	BASE_URL="https://github.com/elixir-lang/expert/releases/download/nightly"
	BINARY_URL="${BASE_URL}/${BINARY_NAME}"
	CHECKSUMS_URL="${BASE_URL}/expert_checksums.txt"

	# Create temporary directory with cleanup trap
	TMPDIR=$(mktemp -d)
	trap 'rm -rf "$TMPDIR"' EXIT

	echo "Downloading binary from: $BINARY_URL"
	if ! curl -fsSL -o "${TMPDIR}/${BINARY_NAME}" "$BINARY_URL"; then
		echo "Error: Failed to download binary" >&2
		exit 1
	fi

	echo "Downloading checksums from: $CHECKSUMS_URL"
	if ! curl -fsSL -o "${TMPDIR}/expert_checksums.txt" "$CHECKSUMS_URL"; then
		echo "Error: Failed to download checksums" >&2
		exit 1
	fi

	echo "Downloads complete. Files saved to temporary directory: $TMPDIR"

	# Verify checksum
	echo "Verifying checksum..."
	EXPECTED_CHECKSUM=$(grep "./${BINARY_NAME}" "${TMPDIR}/expert_checksums.txt" | awk '{print $1}')

	if [ -z "$EXPECTED_CHECKSUM" ]; then
		echo "Error: Checksum not found for ${BINARY_NAME} in checksums file" >&2
		echo "The checksums file may be corrupted or outdated" >&2
		exit 1
	fi

	# Compute actual checksum using appropriate tool
	if command -v sha256sum >/dev/null 2>&1; then
		ACTUAL_CHECKSUM=$(sha256sum "${TMPDIR}/${BINARY_NAME}" | awk '{print $1}')
	else
		ACTUAL_CHECKSUM=$(shasum -a 256 "${TMPDIR}/${BINARY_NAME}" | awk '{print $1}')
	fi

	if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
		echo "Error: Checksum verification failed" >&2
		echo "Expected: $EXPECTED_CHECKSUM" >&2
		echo "Actual:   $ACTUAL_CHECKSUM" >&2
		echo "The downloaded binary may be corrupted or tampered with" >&2
		exit 1
	fi

	echo "Checksum verified successfully"
	echo ""

	# Warn if running as root
	if [ "$(id -u)" -eq 0 ]; then
		echo "Warning: Running as root. Consider installing as a regular user." >&2
		echo ""
	fi

	# Confirm installation location
	if [ $YES_FLAG -eq 0 ]; then
		echo "Install location: $INSTALL_PATH"
		printf "Proceed with installation? [y/N] "
		read -r response
		case "$response" in
		[yY] | [yY][eE][sS])
			echo ""
			;;
		*)
			echo "Installation cancelled"
			exit 0
			;;
		esac
	fi

	# Create target directory
	if ! mkdir -p "$INSTALL_PATH"; then
		echo "Error: Failed to create directory: $INSTALL_PATH" >&2
		exit 1
	fi

	# Check if binary already exists
	TARGET_BINARY="${INSTALL_PATH}/expert"
	if [ -f "$TARGET_BINARY" ]; then
		if [ $YES_FLAG -eq 0 ]; then
			echo "Warning: $TARGET_BINARY already exists"
			printf "Overwrite existing binary? [y/N] "
			read -r response
			case "$response" in
			[yY] | [yY][eE][sS])
				echo ""
				;;
			*)
				echo "Installation cancelled"
				exit 0
				;;
			esac
		else
			echo "Overwriting existing binary at $TARGET_BINARY"
		fi
	fi

	# Install binary
	if ! mv "${TMPDIR}/${BINARY_NAME}" "$TARGET_BINARY"; then
		echo "Error: Failed to install binary to $TARGET_BINARY" >&2
		exit 1
	fi

	# Make executable
	if ! chmod +x "$TARGET_BINARY"; then
		echo "Error: Failed to make binary executable" >&2
		exit 1
	fi

	echo "Successfully installed expert to $TARGET_BINARY"
	echo ""

	# Check if install path is in PATH
	case ":$PATH:" in
	*":$INSTALL_PATH:"*)
		echo "Installation complete! You can now run: expert --help"
		;;
	*)
		echo "Installation complete, but $INSTALL_PATH is not in your PATH"
		echo ""
		echo "To use 'expert' from anywhere, add the following to your shell config:"
		echo ""

		# Detect shell and provide specific instructions
		case "$SHELL" in
		*/bash)
			echo "  For bash (~/.bashrc):"
			echo "    echo 'export PATH=\"$INSTALL_PATH:\$PATH\"' >> ~/.bashrc"
			echo "    source ~/.bashrc"
			;;
		*/zsh)
			echo "  For zsh (~/.zshrc):"
			echo "    echo 'export PATH=\"$INSTALL_PATH:\$PATH\"' >> ~/.zshrc"
			echo "    source ~/.zshrc"
			;;
		*/fish)
			echo "  For fish:"
			echo "    fish_add_path $INSTALL_PATH"
			;;
		*)
			echo "  Add this line to your shell config file:"
			echo "    export PATH=\"$INSTALL_PATH:\$PATH\""
			;;
		esac

		echo ""
		echo "Or run with full path: $TARGET_BINARY --help"
		;;
	esac
}

main
