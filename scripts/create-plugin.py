#!/usr/bin/env python3
"""
PotatoMC Native Plugin Scaffolding Generator
Usage:
    python create-plugin.py MyPlugin --author "Your Name" --platform windows
"""

import sys
import os
import argparse

def main():
    parser = argparse.ArgumentParser(description="Scaffold a new PotatoMC Native Rust Plugin")
    parser.add_argument("name", help="Plugin name (e.g. MyCoolPlugin)")
    parser.add_argument("--author", default="Developer", help="Author name")
    parser.add_argument("--platform", choices=["windows", "linux", "macos"], default="windows")
    parser.add_argument("--out", default=".", help="Output directory")

    args = parser.parse_args()
    name = args.name
    crate_name = name.lower().replace("_", "-")
    struct_name = name.replace("-", "_")
    target_dir = os.path.join(args.out, name)

    if os.path.exists(target_dir):
        print(f"[ERROR] Directory '{target_dir}' already exists!")
        sys.exit(1)

    os.makedirs(os.path.join(target_dir, "src"), exist_ok=True)

    # 1. Cargo.toml
    cargo_toml = f"""[package]
name = "{crate_name}"
version = "0.1.0"
edition = "2024"
authors = ["{args.author}"]
description = "Native plugin for PotatoMC"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = {{ git = "https://github.com/Flaxa-Technologies/potato-api" }}
"""
    with open(os.path.join(target_dir, "Cargo.toml"), "w", encoding="utf-8") as f:
        f.write(cargo_toml)

    # 2. src/lib.rs
    lib_rs = f"""use potato_api::plugin::{{Plugin, PluginContext, PluginMetadata}};
use potato_api::event::{{PlayerJoinEvent, BlockBreakEvent, Cancellable}};
use potato_api::command::{{Command, CommandContext, CommandResult, CommandSender}};
use potato_api::text::Component;
use potato_api::potato_plugin;

#[derive(Default)]
pub struct {struct_name};

impl Plugin for {struct_name} {{
    fn metadata(&self) -> PluginMetadata {{
        PluginMetadata::new("{name}", "1.0.0")
            .author("{args.author}")
            .description("High-performance Native PotatoMC plugin")
    }}

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {{
        context.logger().info("{name} loaded!");
        let _ = context.save_default_config("enabled: true\\n");
        Ok(())
    }}

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {{
        context.logger().info("{name} enabled!");

        context.register_event(|event: &mut PlayerJoinEvent| {{
            let welcome = format!("<gradient:#ffaa00:#ff5555><bold>Welcome, {{}}!</bold></gradient>", event.player.name());
            event.player.send_component(&Component::from_mini_message(&welcome));
        }});

        let cmd = Command::tree("{crate_name[:5]}")
            .executes(|ctx: &CommandContext| -> CommandResult {{
                ctx.sender().send_message("§a{name} is active on PotatoMC!");
                Ok(())
            }});
        context.register_command(cmd);

        Ok(())
    }}

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {{
        context.logger().info("{name} disabled.");
        Ok(())
    }}
}}

potato_plugin!({struct_name});
"""
    with open(os.path.join(target_dir, "src", "lib.rs"), "w", encoding="utf-8") as f:
        f.write(lib_rs)

    # 3. .gitignore
    with open(os.path.join(target_dir, ".gitignore"), "w", encoding="utf-8") as f:
        f.write("/target/\nCargo.lock\n*.dll\n*.so\n*.dylib\n*.pdb\n")

    if args.platform == "windows":
        lib_file = f"{crate_name}.dll"
    elif args.platform == "macos":
        lib_file = f"lib{struct_name}.dylib"
    else:
        lib_file = f"lib{struct_name}.so"

    # 4. README.md
    readme_md = f"""# {name}

Official Paper-grade Native Plugin for PotatoMC.

## Building
```bash
cargo build --release
```
The compiled shared library will be generated at:
`target/release/{lib_file}`

Copy this library file into your PotatoMC server's `plugins/` folder.
"""
    with open(os.path.join(target_dir, "README.md"), "w", encoding="utf-8") as f:
        f.write(readme_md)

    # 5. AGENT.md
    agent_md = f"""# AGENT.md — PotatoMC Native Plugin Development Guide for AI Agents

This file provides critical context and rules for AI coding agents working on this PotatoMC native plugin codebase.

## 1. Project Overview
- **Engine**: PotatoMC (high-performance Rust Minecraft server)
- **Plugin Type**: Native dynamic shared library (`crate-type = ["cdylib"]`)
- **Output Binary**: `target/release/{lib_file}`
- **Runtime Model**: Executes in-process at native C-ABI speed. Zero JVM pauses, zero JNI overhead.

## 2. API Documentation Links
Always consult the official PotatoMC API documentation when writing code:
- **API Repository**: https://github.com/Flaxa-Technologies/potato-api
- **Documentation Hub**: https://github.com/Flaxa-Technologies/potato-api/tree/main/docs
- **Lifecycle & Entrypoint**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/LIFECYCLE.md
- **Event System (26 events)**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md
- **Brigadier Commands**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md
- **Adventure Text & MiniMessage**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md
- **PDC & ItemStacks**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md
- **Scheduler & Concurrency**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md
- **YAML Configuration**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/CONFIGURATION.md
- **BossBar API**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/BOSSBAR.md
- **Paper to PotatoMC Guide**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PAPER_MIGRATION.md

## 3. Build & Check Commands
- Fast syntax/type check: `cargo check`
- Compile release binary: `cargo build --release`

## 4. Agent Coding Rules
1. Always export entrypoint: `potato_plugin!({struct_name});` at the end of `src/lib.rs`.
2. Never block the server tick loop with heavy I/O; use `std::thread::spawn` for database or HTTP calls.
3. Event cancellation: Call `event.set_cancelled(true)` on `Cancellable` events.
4. Verify code compiles cleanly with `cargo check` before finalizing edits.
"""
    with open(os.path.join(target_dir, "AGENT.md"), "w", encoding="utf-8") as f:
        f.write(agent_md)

    # 6. CLAUDE.md
    claude_md = f"""# CLAUDE.md — Instructions for Claude on PotatoMC Native Plugins

## Project Summary
- Native PotatoMC plugin in Rust (Edition 2024)
- Target: `crate-type = ["cdylib"]` -> `target/release/{lib_file}`
- Paper-grade API (MiniMessage, Adventure text, Brigadier trees, PDC, 26 events)

## Commands
- `cargo check` — Check syntax and types.
- `cargo build --release` — Build release library.

## API Documentation
- Full Documentation: https://github.com/Flaxa-Technologies/potato-api/tree/main/docs
- Events: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md
- Commands: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md
- Text/MiniMessage: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md
- PDC/Items: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md
- Scheduler: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md

## Rules
1. Implement `Plugin` trait with `Default`.
2. Export C-ABI symbol with `potato_plugin!({struct_name})`.
3. Use Adventure `Component::from_mini_message` for rich formatting.
4. Always verify code compiles cleanly with `cargo check`.
"""
    with open(os.path.join(target_dir, "CLAUDE.md"), "w", encoding="utf-8") as f:
        f.write(claude_md)

    print(f"[✓] Successfully scaffolded plugin '{name}' at {target_dir}!")
    print(f"To compile: cd {name} && cargo build --release")

if __name__ == "__main__":
    main()
