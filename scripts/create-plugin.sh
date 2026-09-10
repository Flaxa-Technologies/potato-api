#!/usr/bin/env bash
set -e

PLUGIN_NAME=${1:-"MyPotatoPlugin"}
AUTHOR=${2:-"Developer"}
PLATFORM=${3:-"linux"}

CRATE_NAME=$(echo "$PLUGIN_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
STRUCT_NAME=$(echo "$PLUGIN_NAME" | tr '-' '_')

echo "Creating PotatoMC plugin: $PLUGIN_NAME ($CRATE_NAME)..."
mkdir -p "$PLUGIN_NAME/src"

cat <<EOF > "$PLUGIN_NAME/Cargo.toml"
[package]
name = "$CRATE_NAME"
version = "0.1.0"
edition = "2024"
authors = ["$AUTHOR"]
description = "Native plugin for PotatoMC"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { git = "https://github.com/Flaxa-Technologies/potato-api" }
EOF

cat <<EOF > "$PLUGIN_NAME/src/lib.rs"
use potato_api::plugin::{Plugin, PluginContext, PluginMetadata};
use potato_api::event::{PlayerJoinEvent, BlockBreakEvent, Cancellable};
use potato_api::command::{Command, CommandContext, CommandResult, CommandSender};
use potato_api::text::Component;
use potato_api::potato_plugin;

#[derive(Default)]
pub struct $STRUCT_NAME;

impl Plugin for $STRUCT_NAME {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("$PLUGIN_NAME", "1.0.0")
            .author("$AUTHOR")
            .description("A high-performance PotatoMC native plugin")
    }

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME loaded!");
        let _ = context.save_default_config("message: '<gold>Welcome to $PLUGIN_NAME!</gold>'\n");
        Ok(())
    }

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME enabled!");

        context.register_event(|event: &mut PlayerJoinEvent| {
            let msg = format!("<yellow>Welcome, <green>{}</green>!</yellow>", event.player.name());
            event.player.send_component(&Component::from_mini_message(&msg));
        });

        let cmd = Command::tree("${CRATE_NAME:0:5}")
            .executes(|ctx: &CommandContext| -> CommandResult {
                ctx.sender().send_message("§a$PLUGIN_NAME is active!");
                Ok(())
            });
        context.register_command(cmd);

        Ok(())
    }

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME disabled.");
        Ok(())
    }
}

potato_plugin!($STRUCT_NAME);
EOF

cat <<EOF > "$PLUGIN_NAME/.gitignore"
/target/
Cargo.lock
*.dll
*.so
*.dylib
*.pdb
EOF

cat <<EOF > "$PLUGIN_NAME/build.sh"
#!/usr/bin/env bash
cargo build --release
echo "Built binary located in target/release/"
EOF
chmod +x "$PLUGIN_NAME/build.sh"

case "$PLATFORM" in
    windows) LIB_FILE="${CRATE_NAME//-/_}.dll" ;;
    macos) LIB_FILE="lib${CRATE_NAME//-/_}.dylib" ;;
    *) LIB_FILE="lib${CRATE_NAME//-/_}.so" ;;
esac

cat <<EOF > "$PLUGIN_NAME/README.md"
# $PLUGIN_NAME

Official Paper-grade Native Plugin for PotatoMC.

## Building
\`\`\`bash
cargo build --release
\`\`\`
The compiled shared library will be generated at:
\`target/release/$LIB_FILE\`

Copy this library file into your PotatoMC server's \`plugins/\` folder.
EOF

cat <<EOF > "$PLUGIN_NAME/AGENT.md"
# AGENT.md — PotatoMC Native Plugin Development Guide for AI Agents

This file provides critical context and rules for AI coding agents working on this PotatoMC native plugin codebase.

## 1. Project Overview
- **Engine**: PotatoMC (high-performance Rust Minecraft server)
- **Plugin Type**: Native dynamic shared library (\`crate-type = ["cdylib"]\`)
- **Output Binary**: \`target/release/$LIB_FILE\`
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
- Fast syntax/type check: \`cargo check\`
- Compile release binary: \`cargo build --release\`

## 4. Agent Coding Rules
1. Always export entrypoint: \`potato_plugin!($STRUCT_NAME);\` at the end of \`src/lib.rs\`.
2. Never block the server tick loop with heavy I/O; use \`std::thread::spawn\` for database or HTTP calls.
3. Event cancellation: Call \`event.set_cancelled(true)\` on \`Cancellable\` events.
4. Verify code compiles cleanly with \`cargo check\` before finalizing edits.
EOF

cat <<EOF > "$PLUGIN_NAME/CLAUDE.md"
# CLAUDE.md — Instructions for Claude on PotatoMC Native Plugins

## Project Summary
- Native PotatoMC plugin in Rust (Edition 2024)
- Target: \`crate-type = ["cdylib"]\` -> \`target/release/$LIB_FILE\`
- Paper-grade API (MiniMessage, Adventure text, Brigadier trees, PDC, 26 events)

## Commands
- \`cargo check\` — Check syntax and types.
- \`cargo build --release\` — Build release library.

## API Documentation
- Full Documentation: https://github.com/Flaxa-Technologies/potato-api/tree/main/docs
- Events: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md
- Commands: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md
- Text/MiniMessage: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md
- PDC/Items: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md
- Scheduler: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md

## Rules
1. Implement \`Plugin\` trait with \`Default\`.
2. Export C-ABI symbol with \`potato_plugin!($STRUCT_NAME)\`.
3. Use Adventure \`Component::from_mini_message\` for rich formatting.
4. Always verify code compiles cleanly with \`cargo check\`.
EOF

echo "[✓] Plugin $PLUGIN_NAME created successfully!"
echo "To build: cd $PLUGIN_NAME && cargo build --release"
