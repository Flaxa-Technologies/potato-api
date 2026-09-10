# PotatoMC macOS Native Plugin Template (.dylib)

This template provides a production-grade native plugin template for **PotatoMC** running on macOS (Apple Silicon / Intel).

## Quick Start

### 1. Requirements
- [Rust toolchain](https://rustup.rs/) (Rust 2024 edition, 1.85+)
- Xcode Command Line Tools (`xcode-select --install`)

### 2. Build
Using the bash script:
```bash
chmod +x build.sh
./build.sh
```
Or with cargo:
```bash
cargo build --release
```

The output library (`.dylib`) will be generated at `target/release/libmy_potato_plugin_macos.dylib`.

### 3. Deploy
Copy the `.dylib` file to your server's `plugins/` directory:
```bash
cp target/release/libmy_potato_plugin_macos.dylib /path/to/server/plugins/
```
