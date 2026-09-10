#!/usr/bin/env bash
# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - macOS
# ==============================================================================
set -e

echo "=================================================================="
echo "  PotatoMC Native Plugin Development Environment Setup (macOS)    "
echo "=================================================================="

# 1. Check Command Line Tools
echo "[1/3] Checking Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    echo "[!] Xcode Command Line Tools not detected. Prompting installation..."
    xcode-select --install
    echo "Please complete the installation dialog and re-run this script."
    exit 1
fi
echo "[✓] Xcode Command Line Tools detected."

# 2. Check for existing Cargo / Rust
echo "[2/3] Checking Rust toolchain..."

if ! command -v cargo &> /dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
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
        echo "[i] Auto-installation cancelled. Please install Rust from https://rustup.rs/"
        exit 0
    fi

    echo "[*] Downloading and installing rustup..."
    TMP_INIT="/tmp/rustup-init-$$.sh"
    if curl --proto '=https' --tlsv1.2 -sSfL https://sh.rustup.rs -o "$TMP_INIT"; then
        sh "$TMP_INIT" -y --default-toolchain stable --profile default
        rm -f "$TMP_INIT"
    elif command -v brew &> /dev/null; then
        echo "[!] rustup download failed. Installing via Homebrew..."
        brew install rust
    fi

    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    export PATH="$HOME/.cargo/bin:$PATH"

    if command -v cargo &> /dev/null; then
        RUST_VER=$(cargo --version)
        echo "[✓] Rust installed successfully: $RUST_VER"
    else
        echo "[ERROR] Cargo could not be found in PATH after install."
        exit 1
    fi
fi

# 3. Add Apple Silicon & Intel Targets
echo "[3/3] Checking architecture targets..."
if command -v rustup &> /dev/null; then
    rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true
    echo "[✓] Configured targets for macOS."
fi

echo "=================================================================="
echo "  macOS plugin development setup is complete!                     "
echo "=================================================================="
