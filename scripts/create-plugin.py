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

    print(f"[✓] Successfully scaffolded plugin '{name}' at {target_dir}!")
    print(f"To compile: cd {name} && cargo build --release")

if __name__ == "__main__":
    main()
