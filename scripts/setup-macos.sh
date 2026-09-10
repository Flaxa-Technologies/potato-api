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

# 2. Check/Install Rust
echo "[2/3] Checking Rust toolchain..."
if ! command -v cargo &> /dev/null; then
    echo "[!] Cargo not found! Installing via https://sh.rustup.rs..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source "$HOME/.cargo/env"
fi
RUST_VER=$(cargo --version)
echo "[✓] Using: $RUST_VER"

# 3. Add Apple Silicon & Intel Targets
echo "[3/3] Adding macOS architecture targets..."
rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true
echo "[✓] Configured targets for macOS."

echo "------------------------------------------------------------------"
echo "macOS plugin development setup is complete!"
echo "Build template: cd templates/macos && ./build.sh"
echo "------------------------------------------------------------------"
