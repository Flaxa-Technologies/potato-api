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

# 1. System Build Dependencies
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
echo "[✓] Build dependencies verified."

# 2. Check for Cargo / Rust in existing paths
echo "[2/4] Checking for existing Rust toolchain..."

if ! command -v cargo &> /dev/null; then
    for cargo_env in "$HOME/.cargo/env" "/usr/local/cargo/env" "/root/.cargo/env"; do
        if [ -f "$cargo_env" ]; then
            . "$cargo_env" 2>/dev/null || true
        fi
    done
    for cargo_bin in "$HOME/.cargo/bin" "/usr/local/cargo/bin" "/root/.cargo/bin"; do
        if [ -d "$cargo_bin" ]; then
            export PATH="$cargo_bin:$PATH"
        fi
    done
fi

if command -v cargo &> /dev/null; then
    RUST_VER=$(cargo --version)
    echo "[✓] Rust toolchain detected: $RUST_VER"
else
    echo ""
    echo "[!] Cargo / Rust toolchain was not found on your system."

    # Ask user for automatic installation
    DO_INSTALL="y"
    if [ -e /dev/tty ]; then
        read -r -p "Would you like to automatically install Rust and Cargo now? [Y/n]: " USER_CHOICE < /dev/tty || USER_CHOICE="y"
        if [[ "$USER_CHOICE" =~ ^[Nn] ]]; then
            DO_INSTALL="n"
        fi
    fi

    if [ "$DO_INSTALL" != "y" ]; then
        echo ""
        echo "[i] Auto-installation cancelled."
        echo "Please install Rust manually from: https://rustup.rs/"
        echo "Then re-run this setup script."
        exit 0
    fi

    echo ""
    echo "[*] Proceeding with automatic Rust installation..."

    INSTALL_SUCCESS=false
    TMP_INIT="/tmp/rustup-init-$$.sh"

    echo "[i] Downloading rustup installer from https://sh.rustup.rs..."
    if curl --proto '=https' --tlsv1.2 -sSfL https://sh.rustup.rs -o "$TMP_INIT"; then
        if sh "$TMP_INIT" -y --default-toolchain stable --profile default; then
            INSTALL_SUCCESS=true
        fi
        rm -f "$TMP_INIT"
    fi

    # Fallback to distro package manager if rustup download failed
    if [ "$INSTALL_SUCCESS" = false ]; then
        echo "[!] rustup installation was unavailable. Attempting package manager fallback..."
        if command -v apt-get &> /dev/null; then
            $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y cargo rustc && INSTALL_SUCCESS=true
        elif command -v pacman &> /dev/null; then
            $SUDO pacman -S --noconfirm rust && INSTALL_SUCCESS=true
        elif command -v dnf &> /dev/null; then
            $SUDO dnf install -y cargo rust && INSTALL_SUCCESS=true
        fi
    fi

    # Reload environment
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    export PATH="$HOME/.cargo/bin:$PATH"

    if command -v cargo &> /dev/null; then
        RUST_VER=$(cargo --version)
        echo "[✓] Successfully installed: $RUST_VER"
    else
        echo "[ERROR] Cargo installation could not be completed automatically."
        echo "Please install Rust manually via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
fi

# 3. Ensure stable toolchain
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
