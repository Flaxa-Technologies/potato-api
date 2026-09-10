#!/usr/bin/env bash
set -e

echo "========================================================"
echo "  PotatoMC Linux Plugin Build Script (.so)"
echo "========================================================"
echo ""

if ! command -v cargo &> /dev/null; then
    echo "[ERROR] 'cargo' not found in PATH! Install Rust via https://rustup.rs/"
    exit 1
fi

echo "[1/2] Compiling native shared library (.so) in release mode..."
cargo build --release

SO_FILE="target/release/libmy_potato_plugin_linux.so"

if [ -f "$SO_FILE" ]; then
    echo ""
    echo "[2/2] Success! Produced: $SO_FILE"
    if [ -d "../../plugins" ]; then
        cp -f "$SO_FILE" "../../plugins/"
        echo "Deployed to ../../plugins/"
    fi
fi

echo "========================================================"
echo "  Build complete! Drop the .so into your server plugins/"
echo "========================================================"
