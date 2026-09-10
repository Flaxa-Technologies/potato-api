#!/usr/bin/env bash
set -e

echo "========================================================"
echo "  PotatoMC macOS Plugin Build Script (.dylib)"
echo "========================================================"
echo ""

if ! command -v cargo &> /dev/null; then
    echo "[ERROR] 'cargo' not found in PATH! Install Rust via https://rustup.rs/"
    exit 1
fi

echo "[1/2] Compiling native dynamic library (.dylib) in release mode..."
cargo build --release

DYLIB_FILE="target/release/libmy_potato_plugin_macos.dylib"

if [ -f "$DYLIB_FILE" ]; then
    echo ""
    echo "[2/2] Success! Produced: $DYLIB_FILE"
    if [ -d "../../plugins" ]; then
        cp -f "$DYLIB_FILE" "../../plugins/"
        echo "Deployed to ../../plugins/"
    fi
fi

echo "========================================================"
echo "  Build complete! Drop the .dylib into server plugins/"
echo "========================================================"
