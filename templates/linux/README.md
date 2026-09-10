# PotatoMC Linux Native Plugin Template (.so)

This template provides a production-grade native plugin template for **PotatoMC** running on Linux servers.

## Quick Start

### 1. Requirements
- [Rust toolchain](https://rustup.rs/) (Rust 2024 edition, 1.85+)
- Standard Linux build utilities (`build-essential`, `gcc`, `libc6-dev`)

```bash
# Ubuntu / Debian
sudo apt-get update && sudo apt-get install -y build-essential curl

# Arch Linux
sudo pacman -S base-devel

# Fedora / RHEL
sudo dnf groupinstall "Development Tools"
```

### 2. Build
Using the bash script:
```bash
chmod +x build.sh
./build.sh
```
Or with `make`:
```bash
make release
```
Or directly with `cargo`:
```bash
cargo build --release
```

The output shared object (`.so`) is located at `target/release/libmy_potato_plugin_linux.so`.

### 3. Deploy
Copy the `.so` file to your server's `plugins/` directory:
```bash
cp target/release/libmy_potato_plugin_linux.so /path/to/server/plugins/
```

PotatoMC will dynamically link and start your native plugin upon startup or reload!

## Included Features
- **Adventure Text & MiniMessage**: Native parsing of `<gradient>`, `<bold>`, hex colors
- **Tab List Header & Footer**: Direct control over client player list packets
- **Event Observers**: `PlayerJoinEvent`, `BlockBreakEvent` with `set_cancelled(true)`, `PlayerInteractEvent`, `PlayerChatEvent`
- **Brigadier Commands**: Tree-based syntax `/linuxplugin <greet <target> | item | bossbar | broadcast <msg>>`
- **PDC & ItemStacks**: Persistent typed metadata and custom enchantments
- **Schedulers**: Sync delayed tasks, periodic timers, and async background workers
