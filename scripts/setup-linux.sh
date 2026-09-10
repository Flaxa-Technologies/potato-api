#!/usr/bin/env bash
# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - Linux
# ==============================================================================
set -e

echo "=================================================================="
echo "  PotatoMC Native Plugin Development Environment Setup (Linux)    "
echo "=================================================================="

# 1. Detect Package Manager & Install Build Essentials
echo "[1/4] Installing system dependencies..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y build-essential curl pkg-config libssl-dev
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm base-devel curl pkgconf openssl
elif command -v dnf &> /dev/null; then
    sudo dnf groupinstall -y "Development Tools" && sudo dnf install -y curl pkgconf-pkg-config openssl-devel
else
    echo "[!] Unknown package manager. Please ensure gcc/clang, make, and build essentials are installed."
fi
echo "[✓] System packages installed."

# 2. Check/Install Rust
echo "[2/4] Checking Rust toolchain..."
if ! command -v cargo &> /dev/null; then
    echo "[!] Cargo not found! Installing via https://sh.rustup.rs..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable < /dev/null
    source "$HOME/.cargo/env" 2>/dev/null || true
fi

RUST_VER=$(cargo --version)
echo "[✓] Using: $RUST_VER"

# 3. Ensure stable toolchain
echo "[3/4] Ensuring latest stable toolchain..."
rustup default stable
rustup update stable
echo "[✓] Rust toolchain updated."

# 4. Summary & Instructions
echo "[4/4] Environment configured successfully!"
echo "------------------------------------------------------------------"
echo "You are ready to build PotatoMC Linux plugins (.so)!"
echo ""
echo "To scaffold a new plugin:"
echo "  ./scripts/create-plugin.sh my-cool-plugin --os linux"
echo ""
echo "Or build the included Linux template:"
echo "  cd templates/linux"
echo "  ./build.sh"
echo "------------------------------------------------------------------"
