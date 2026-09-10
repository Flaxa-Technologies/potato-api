# PotatoMC Windows Native Plugin Template (.dll)

This template provides a ready-to-build, production-grade native plugin for **PotatoMC** running on Windows.

## Quick Start

### 1. Requirements
- [Rust toolchain](https://rustup.rs/) (Rust 2024 edition, 1.85+)
- Visual Studio C++ Build Tools (MSVC)

### 2. Build
Using Command Prompt:
```cmd
build.bat
```
Or using PowerShell:
```powershell
.\build.ps1
```
Or manually with Cargo:
```cmd
cargo build --release
```

The output DLL will be generated at `target\release\my_potato_plugin.dll`.

### 3. Deploy
Copy `target\release\my_potato_plugin.dll` into your PotatoMC server's `plugins/` directory:
```cmd
copy target\release\my_potato_plugin.dll ..\..\plugins\
```

Start or reload your server, and the plugin will automatically load!

## Features Included in This Template
- **Adventure Text & MiniMessage**: `<gradient>`, `<bold>`, hex color tags
- **Tab List Header & Footer**: Live tab list customization via native packets
- **Event Listeners**: Player join, bedrock break prevention with `set_cancelled(true)`, block interact, chat
- **Brigadier Commands**: Fluent tree `/winplugin <greet <name> | item | bossbar | broadcast <msg>>`
- **Persistent Data Container (PDC)**: Attach typed string/int/byte metadata to `ItemStack`
- **Schedulers**: Sync delayed tasks, periodic timers, and async background workers
