<p align="center">
  <img src="LOGO.png" alt="PotatoMC Logo" width="280"/>
</p>

# PotatoMC Native Plugin API (`potato-api`)

<p align="center">
  <b>High-Performance Paper-Grade Native Rust Plugin Development Kit for PotatoMC</b><br>
  Zero JVM Overhead • Sub-Millisecond Native Latency • Full Paper Parity • Zero GC Pauses
</p>

<p align="center">
  <a href="https://potatomc.flaxa.in/"><img src="https://img.shields.io/badge/Official_Website-potatomc.flaxa.in-FF8800?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Website"></a>
  <a href="https://discord.com/invite/UUaNzfZyc6"><img src="https://img.shields.io/badge/Discord-Flaxa_Studios-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>
  <a href="https://github.com/Flaxa-Technologies/potato-api"><img src="https://img.shields.io/badge/GitHub-potato--api-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"></a>
  <img src="https://img.shields.io/badge/Rust-2024_Edition-black?style=for-the-badge&logo=rust" alt="Rust Edition">
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge" alt="License">
</p>

---

## 🥔 Welcome to PotatoMC

**PotatoMC** is a next-generation, native Minecraft server engine written in Rust. The **PotatoMC Native Plugin API (`potato-api`)** empowers developers to build ultra-fast, native plugins compiled directly to dynamic libraries:

- **Windows**: `.dll` (Dynamic-Link Library)
- **Linux**: `.so` (Shared Object)
- **macOS**: `.dylib` (Dynamic Library)

By executing natively in-process, PotatoMC plugins eliminate Java Virtual Machine (JVM) overhead, garbage-collection hitches, and JNI boundary penalties while delivering the rich developer experience of Bukkit, Spigot, and Paper.

---

## ⚡ Quick Start

### 1. Set Up Your Environment

Run the automated setup script for your platform:

| Platform | Setup Command |
|---|---|
| **Windows** | `powershell .\scripts\setup-windows.ps1` or run `scripts\setup-windows.bat` |
| **Linux** | `chmod +x scripts/setup-linux.sh && ./scripts/setup-linux.sh` |
| **macOS** | `chmod +x scripts/setup-macos.sh && ./scripts/setup-macos.sh` |

### 2. Scaffold a New Plugin

Use our automated generator to scaffold a fresh plugin in seconds:

```bash
# Using Python (Cross-Platform)
python scripts/create-plugin.py MyAwesomePlugin --author "Your Name" --platform windows

# Or using PowerShell (Windows)
powershell .\scripts\create-plugin.ps1 -Name MyAwesomePlugin -Platform windows

# Or using Bash (Linux/macOS)
./scripts/create-plugin.sh my-awesome-plugin "Your Name" linux
```

### 3. Add to an Existing Project (`Cargo.toml`)

In your plugin's `Cargo.toml`:

```toml
[package]
name = "my-awesome-plugin"
version = "0.1.0"
edition = "2024"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { git = "https://github.com/Flaxa-Technologies/potato-api" }
```

---

## 🚀 Writing Your First Plugin

```rust
use potato_api::plugin::{Plugin, PluginContext, PluginMetadata};
use potato_api::event::{PlayerJoinEvent, BlockBreakEvent, Cancellable};
use potato_api::command::{Command, CommandContext, CommandResult, CommandSender};
use potato_api::text::Component;
use potato_api::potato_plugin;

#[derive(Default)]
pub struct MyFirstPlugin;

impl Plugin for MyFirstPlugin {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("MyFirstPlugin", "1.0.0")
            .author("Developer")
            .description("My first native PotatoMC plugin")
    }

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("MyFirstPlugin enabled at native speed!");

        // 1. Event: Welcome message with MiniMessage
        context.register_event(|event: &mut PlayerJoinEvent| {
            let welcome = format!(
                "<gradient:#ffaa00:#ff5555><bold>Welcome to PotatoMC, {}!</bold></gradient>",
                event.player.name()
            );
            event.player.send_component(&Component::from_mini_message(&welcome));
        });

        // 2. Event: Bedrock break cancellation
        context.register_event(|event: &mut BlockBreakEvent| {
            if event.block.block_type == "minecraft:bedrock" {
                event.set_cancelled(true);
                if let Some(ref player) = event.player {
                    player.send_message("§cYou cannot break bedrock!");
                }
            }
        });

        // 3. Command: /ping -> Pong!
        let cmd = Command::tree("ping")
            .description("Responds with Pong!")
            .executes(|ctx: &CommandContext| -> CommandResult {
                ctx.sender().send_message("§a[PotatoMC] Pong!");
                Ok(())
            });
        context.register_command(cmd);

        Ok(())
    }
}

// Export native entrypoint symbol
potato_plugin!(MyFirstPlugin);
```

### 4. Build and Deploy

#### On Windows:
```cmd
cargo build --release
copy target\release\my_awesome_plugin.dll C:\path\to\server\plugins\
```

#### On Linux:
```bash
cargo build --release
cp target/release/libmy_awesome_plugin.so /path/to/server/plugins/
```

#### On macOS:
```bash
cargo build --release
cp target/release/libmy_awesome_plugin.dylib /path/to/server/plugins/
```

Drop the compiled dynamic library directly into your PotatoMC server's `plugins/` directory and run your server!

---

## 📦 Production Templates

Pre-configured, production-ready templates are included in the `templates/` folder:

- 🪟 **[Windows Template (`.dll`)](templates/windows/)**: Includes `build.bat`, `build.ps1`, `Cargo.toml`, and comprehensive sample code.
- 🐧 **[Linux Template (`.so`)](templates/linux/)**: Includes `build.sh`, `Makefile`, `Cargo.toml`, and ELF-optimized configuration.
- 🍎 **[macOS Template (`.dylib`)](templates/macos/)**: Includes `build.sh`, `Cargo.toml`, and universal target setup.

---

## 📖 Complete Documentation

Explore the complete API reference in the [`docs/`](docs/) directory:

- 🏗️ **[Plugin Lifecycle & Architecture](docs/LIFECYCLE.md)**
- ⚡ **[Event System & 26-Event Catalog](docs/EVENTS.md)**
- 🌲 **[Brigadier Command Tree API](docs/COMMANDS.md)**
- 🎨 **[Adventure Text & MiniMessage](docs/TEXT_AND_MINIMESSAGE.md)**
- 📦 **[Persistent Data Container (PDC) & Items](docs/PDC_AND_ITEMS.md)**
- ⏱️ **[Scheduler & Concurrency Model](docs/SCHEDULER.md)**
- ⚙️ **[Configuration API (YAML)](docs/CONFIGURATION.md)**
- 📊 **[Adventure BossBar API](docs/BOSSBAR.md)**
- 🔄 **[Paper Java to PotatoMC Rust Migration Guide](docs/PAPER_MIGRATION.md)**

---

## 🌐 Community & Links

- **Official Website**: [https://potatomc.flaxa.in/](https://potatomc.flaxa.in/)
- **Discord Community**: [Flaxa Studios & Inxtra Launcher](https://discord.com/invite/UUaNzfZyc6)
- **Parent Organization**: Flaxa Studios / Flaxa Technologies
- **Issue Tracker**: [GitHub Issues](https://github.com/Flaxa-Technologies/potato-api/issues)

---

## ⚖️ License

The PotatoMC Native Plugin API is licensed under the [GNU General Public License v3.0](LICENSE).
Plugins built against `potato-api` can be licensed according to their author's choice.
