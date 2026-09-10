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
        . "$HOME/.cargo/env"
    fi
    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
fi

if ! command -v cargo &> /dev/null; then
    echo "[!] Cargo not found in PATH! Downloading and installing rustup..."
    TMP_RUSTUP=$(mktemp /tmp/rustup-init.XXXXXX.sh 2>/dev/null || mktemp)

    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$TMP_RUSTUP"; then
        sh "$TMP_RUSTUP" -y --default-toolchain stable --profile default
        rm -f "$TMP_RUSTUP"
    else
        echo "[ERROR] Failed to download rustup installer."
        rm -f "$TMP_RUSTUP"
        exit 1
    fi

    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if command -v cargo &> /dev/null; then
    RUST_VER=$(cargo --version)
    echo "[✓] Using: $RUST_VER"
else
    echo "[ERROR] Cargo could not be found or initialized!"
    echo "Please run: source \$HOME/.cargo/env"
    exit 1
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
