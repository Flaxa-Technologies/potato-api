#!/usr/bin/env bash
# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - Linux
# ==============================================================================
set -e

echo "=================================================================="
echo "  PotatoMC Native Plugin Development Environment Setup (Linux)    "
echo "=================================================================="

# Determine sudo requirement
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
    SUDO="sudo"
fi

# 1. Detect Package Manager & Install Build Essentials
echo "[1/4] Checking and installing system build dependencies..."
if command -v apt-get &> /dev/null; then
    $SUDO apt-get update -y
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential curl pkg-config libssl-dev
elif command -v pacman &> /dev/null; then
    $SUDO pacman -S --noconfirm base-devel curl pkgconf openssl
elif command -v dnf &> /dev/null; then
    $SUDO dnf groupinstall -y "Development Tools" && $SUDO dnf install -y curl pkgconf-pkg-config openssl-devel
else
    echo "[i] Custom Linux distribution detected. Ensure gcc/clang, make, and build essentials are present."
fi
echo "[✓] System packages verified."

# 2. Check for existing Cargo / Rust in PATH or standard directories
echo "[2/4] Checking Rust toolchain..."

if ! command -v cargo &> /dev/null; then
    # Check if cargo was installed previously in standard cargo locations
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    elif [ -f "/usr/local/cargo/env" ]; then
        . "/usr/local/cargo/env"
    fi

    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    if [ -d "/usr/local/cargo/bin" ]; then
        export PATH="/usr/local/cargo/bin:$PATH"
    fi
fi

# If cargo is still not found, download and install via rustup safely (avoiding broken pipes)
if ! command -v cargo &> /dev/null; then
    echo "[!] Cargo not found in PATH. Downloading and installing rustup..."
    TMP_RUSTUP=$(mktemp /tmp/rustup-init.XXXXXX.sh 2>/dev/null || mktemp)
    
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$TMP_RUSTUP"; then
        sh "$TMP_RUSTUP" -y --default-toolchain stable --profile default
        rm -f "$TMP_RUSTUP"
    else
        echo "[ERROR] Failed to download rustup installer."
        rm -f "$TMP_RUSTUP"
        exit 1
    fi

    # Load environment
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Verify cargo availability
if command -v cargo &> /dev/null; then
    RUST_VER=$(cargo --version)
    echo "[✓] Detected: $RUST_VER"
else
    echo "[ERROR] Cargo could not be found or initialized!"
    echo "Please ensure ~/.cargo/bin is in your PATH, or run: source \$HOME/.cargo/env"
    exit 1
fi

# 3. Ensure stable toolchain & components
echo "[3/4] Checking Rust toolchain status..."
if command -v rustup &> /dev/null; then
    rustup default stable 2>/dev/null || true
    echo "[✓] Default toolchain set to stable."
fi

# 4. Summary & Instructions
echo "[4/4] Setup complete!"
echo "=================================================================="
echo "  PotatoMC Linux Native Plugin Development Environment is Ready! "
echo "=================================================================="
echo ""
echo "To scaffold a new plugin:"
echo "  ./scripts/create-plugin.sh my-cool-plugin \"Your Name\" linux"
echo ""
echo "Or build the included Linux template:"
echo "  cd templates/linux"
echo "  ./build.sh"
echo "=================================================================="
