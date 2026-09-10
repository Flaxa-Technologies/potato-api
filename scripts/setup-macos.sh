#!/usr/bin/env bash
# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - macOS
# ==============================================================================
set -e

echo "=================================================================="
echo "  PotatoMC Native Plugin Development Environment Setup (macOS)    "
echo "=================================================================="

# 1. Check Command Line Tools
echo "[1/3] Checking Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    echo "[!] Xcode Command Line Tools not detected. Prompting installation..."
    xcode-select --install
    echo "Please complete the installation dialog and re-run this script."
    exit 1
fi
echo "[✓] Xcode Command Line Tools detected."

# 2. Check for existing Cargo / Rust
echo "[2/3] Checking Rust toolchain..."

if ! command -v cargo &> /dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
fi

if command -v cargo &> /dev/null; then
    RUST_VER=$(cargo --version)
    echo "[✓] Rust toolchain detected: $RUST_VER"
else
    echo ""
    echo "[!] Cargo / Rust toolchain was not found on your system."

    # Ask user for automatic installation
    DO_INSTALL="y"
    if [ -e /dev/tty ]; then
        read -r -p "Would you like to automatically install Rust and Cargo now? [Y/n]: " USER_CHOICE < /dev/tty || USER_CHOICE="y"
        if [[ "$USER_CHOICE" =~ ^[Nn] ]]; then
            DO_INSTALL="n"
        fi
    fi

    if [ "$DO_INSTALL" != "y" ]; then
        echo ""
        echo "[i] Auto-installation cancelled. Please install Rust from https://rustup.rs/"
        exit 0
    fi

    echo "[*] Downloading and installing rustup..."
    TMP_INIT="/tmp/rustup-init-$$.sh"
    if curl --proto '=https' --tlsv1.2 -sSfL https://sh.rustup.rs -o "$TMP_INIT"; then
        sh "$TMP_INIT" -y --default-toolchain stable --profile default
        rm -f "$TMP_INIT"
    elif command -v brew &> /dev/null; then
        echo "[!] rustup download failed. Installing via Homebrew..."
        brew install rust
    fi

    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    export PATH="$HOME/.cargo/bin:$PATH"

    if command -v cargo &> /dev/null; then
        RUST_VER=$(cargo --version)
        echo "[✓] Rust installed successfully: $RUST_VER"
    else
        echo "[ERROR] Cargo could not be found in PATH after install."
        exit 1
    fi
fi

# 3. Add Apple Silicon & Intel Targets
echo "[3/3] Checking architecture targets..."
if command -v rustup &> /dev/null; then
    rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true
    echo "[✓] Configured targets for macOS."
fi

# 4. Interactive Scaffolding
echo "=================================================================="
echo "  macOS plugin development setup is complete!                     "
echo "=================================================================="
echo ""

DO_SCAFFOLD="y"
if [ -e /dev/tty ]; then
    read -r -p "Would you like to set up a new plugin template here now? [Y/n]: " WANT_SCAFFOLD < /dev/tty || WANT_SCAFFOLD="y"
    if [[ "$WANT_SCAFFOLD" =~ ^[Nn] ]]; then
        DO_SCAFFOLD="n"
    fi
fi

if [ "$DO_SCAFFOLD" = "y" ]; then
    PLUGIN_NAME="MyPotatoPlugin"
    PLUGIN_AUTHOR="Developer"
    TARGET_DIR="."

    if [ -e /dev/tty ]; then
        read -r -p "Enter Plugin Name [default: MyPotatoPlugin]: " INPUT_NAME < /dev/tty || INPUT_NAME=""
        if [ -n "$INPUT_NAME" ]; then
            PLUGIN_NAME="$INPUT_NAME"
        fi

        read -r -p "Enter Author Name [default: Developer]: " INPUT_AUTHOR < /dev/tty || INPUT_AUTHOR=""
        if [ -n "$INPUT_AUTHOR" ]; then
            PLUGIN_AUTHOR="$INPUT_AUTHOR"
        fi

        read -r -p "Create in current directory '.' or new subfolder './$PLUGIN_NAME'? [1=Current dir, 2=Subfolder] (Default: 1): " DIR_CHOICE < /dev/tty || DIR_CHOICE="1"
        if [ "$DIR_CHOICE" = "2" ]; then
            TARGET_DIR="./$PLUGIN_NAME"
        fi
    fi

    CRATE_NAME=$(echo "$PLUGIN_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    STRUCT_NAME=$(echo "$PLUGIN_NAME" | tr '-' '_')
    CMD_NAME=$(echo "$CRATE_NAME" | cut -c 1-8)

    mkdir -p "$TARGET_DIR/src"

    cat <<EOF > "$TARGET_DIR/Cargo.toml"
[package]
name = "$CRATE_NAME"
version = "0.1.0"
edition = "2024"
authors = ["$PLUGIN_AUTHOR"]
description = "Native macOS PotatoMC Plugin (.dylib)"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { git = "https://github.com/Flaxa-Technologies/potato-api" }
EOF

    cat <<EOF > "$TARGET_DIR/src/lib.rs"
use std::time::Duration;
use potato_api::bossbar::{BossBar, BossBarColor, BossBarStyle};
use potato_api::command::{Argument, Command, CommandContext, CommandResult, CommandSender};
use potato_api::event::{
    BlockBreakEvent, Cancellable, PlayerChatEvent, PlayerInteractEvent, PlayerJoinEvent,
};
use potato_api::plugin::{Plugin, PluginContext, PluginMetadata};
use potato_api::potato_plugin;
use potato_api::text::{Component, NamedTextColor};
use potato_api::types::{ItemStack, PersistentDataContainer};

#[derive(Default)]
pub struct $STRUCT_NAME;

impl Plugin for $STRUCT_NAME {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("$PLUGIN_NAME", "1.0.0")
            .author("$PLUGIN_AUTHOR")
            .description("Official Paper-grade Native macOS PotatoMC Plugin (.dylib)")
    }

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME loaded on macOS host!");
        let default_cfg = r#"# $PLUGIN_NAME Configuration
server:
  welcome_message: "<gradient:#ffaa00:#ff5555><bold>Welcome, {player}!</bold></gradient> Running on PotatoMC!"
  tab_header: "<gold><bold>PotatoMC macOS Server</bold></gold>"
  tab_footer: "<gray>Paper-grade Native Plugin (.dylib)</gray>"
features:
  protect_bedrock: true
"#;
        let _ = context.save_default_config(default_cfg);
        Ok(())
    }

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        let logger = context.logger();
        logger.info("$PLUGIN_NAME enabling at native speed...");

        let config = context.config();
        let welcome_template = config.get_string_or(
            "server.welcome_message",
            "Welcome, {player}! Running on PotatoMC!",
        );
        let tab_header = config.get_string_or("server.tab_header", "<gold>PotatoMC</gold>");
        let tab_footer = config.get_string_or("server.tab_footer", "<gray>Native macOS .dylib</gray>");
        let protect_bedrock = config.get_bool_or("features.protect_bedrock", true);

        // 1. PlayerJoinEvent
        let join_template = welcome_template.clone();
        let header_str = tab_header.clone();
        let footer_str = tab_footer.clone();
        context.register_event(move |event: &mut PlayerJoinEvent| {
            let player = &event.player;
            let player_name = player.name();

            let formatted = join_template.replace("{player}", &player_name);
            let component = Component::from_mini_message(&formatted);
            player.send_component(&component);

            let h = Component::from_mini_message(&header_str);
            let f = Component::from_mini_message(&footer_str);
            player.set_player_list_header_footer(&h.to_legacy_string(), &f.to_legacy_string());
        });

        // 2. BlockBreakEvent
        if protect_bedrock {
            context.register_event(move |event: &mut BlockBreakEvent| {
                if event.block.block_type == "minecraft:bedrock" {
                    event.set_cancelled(true);
                    if let Some(ref player) = event.player {
                        player.send_message("§cYou cannot break bedrock!");
                    }
                }
            });
        }

        // 3. PlayerInteractEvent
        context.register_event(move |event: &mut PlayerInteractEvent| {
            if let Some(ref block) = event.clicked_block {
                if block.block_type == "minecraft:diamond_block" {
                    event.player.send_message("§b✨ You tapped a Diamond Block!");
                }
            }
        });

        // 4. Commands
        let cmd = Command::tree("$CMD_NAME")
            .description("Command from $PLUGIN_NAME")
            .subcommand(
                Command::tree("greet")
                    .argument(Argument::word("target"))
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let target = ctx.get_string("target").unwrap_or("Friend");
                        let comp = Component::text("Hello, ")
                            .color(NamedTextColor::Yellow)
                            .append(Component::text(target).color(NamedTextColor::Green).bold())
                            .append(Component::text(" from macOS native plugin!"));

                        match ctx.sender() {
                            CommandSender::Player(p) => p.send_component(&comp),
                            CommandSender::Console(c) => c.send_message(&comp.to_plain_text()),
                        }
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("item")
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let mut item = ItemStack::new("minecraft:diamond_sword", 1);
                        item.set_custom_name("§6§lmacOS Blade");
                        item.add_lore("§7Native .dylib item");
                        item.add_enchantment("minecraft:sharpness", 5);

                        let mut pdc = PersistentDataContainer::new();
                        pdc.set_string("rpg:kernel", "Darwin");
                        item.set_pdc(pdc);

                        ctx.sender().send_message(&format!(
                            "§aCreated item '{}' with PDC: {:?}",
                            item.custom_name.as_deref().unwrap_or(""),
                            item.pdc().get_string("rpg:kernel")
                        ));
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("bossbar")
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let bar = BossBar::new(
                            "§6§lmacOS Core Titan",
                            BossBarColor::Yellow,
                            BossBarStyle::Notched10,
                        ).with_progress(0.85);

                        ctx.sender().send_message(&format!("§aCreated BossBar '{}'", bar.title));
                        Ok(())
                    }),
            )
            .executes(|ctx: &CommandContext| -> CommandResult {
                ctx.sender().send_message("§eUsage: /$CMD_NAME <greet <target> | item | bossbar>");
                Ok(())
            });

        context.register_command(cmd);

        // 5. Scheduler
        let setup_logger = context.logger().clone();
        context.scheduler().run_task_later(Duration::from_secs(5), move || {
            setup_logger.info("Delayed 5-second task executed on macOS main thread.");
        });

        let timer_logger = context.logger().clone();
        let _ = context.scheduler().run_task_repeating(
            Duration::from_secs(60),
            Duration::from_secs(60),
            move || {
                timer_logger.debug("macOS plugin periodic heartbeat tick.");
            },
        );

        let async_logger = context.logger().clone();
        std::thread::spawn(move || {
            async_logger.info("Async background worker running off main thread!");
        });

        logger.info("$PLUGIN_NAME enabled successfully on macOS (.dylib)!");
        Ok(())
    }

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME disabled.");
        Ok(())
    }
}

potato_plugin!($STRUCT_NAME);
EOF

    cat <<EOF > "$TARGET_DIR/build.sh"
#!/usr/bin/env bash
set -e
cargo build --release
echo "Built: target/release/lib${CRATE_NAME//-/_}.dylib"
EOF
    chmod +x "$TARGET_DIR/build.sh"

    cat <<EOF > "$TARGET_DIR/.gitignore"
/target/
Cargo.lock
*.so
*.dll
*.dylib
*.pdb
EOF

    cat <<EOF > "$TARGET_DIR/README.md"
# $PLUGIN_NAME

Official Paper-grade Native macOS Plugin for PotatoMC (.dylib).

## Build
\`\`\`bash
cargo build --release
\`\`\`
Output will be at \`target/release/lib${CRATE_NAME//-/_}.dylib\`.
EOF

    # Write AGENT.md
    cat <<EOF > "$TARGET_DIR/AGENT.md"
# AGENT.md — PotatoMC Native Plugin Development Guide for AI Agents

This file provides critical context and rules for AI coding agents working on this PotatoMC native plugin codebase.

## 1. Project Overview
- **Engine**: PotatoMC (high-performance Rust Minecraft server)
- **Plugin Type**: Native dynamic shared library (\`crate-type = ["cdylib"]\`)
- **Output Binary**: \`target/release/lib${CRATE_NAME//-/_}.dylib\`
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

    # Write CLAUDE.md
    cat <<EOF > "$TARGET_DIR/CLAUDE.md"
# CLAUDE.md — Instructions for Claude on PotatoMC Native Plugins

## Project Summary
- Native PotatoMC plugin in Rust (Edition 2024)
- Target: \`crate-type = ["cdylib"]\` -> \`target/release/lib${CRATE_NAME//-/_}.dylib\`
- Paper-grade API (MiniMessage, Adventure text, Brigadier trees, PDC, 26 events)

## Commands
- \`cargo check\` — Check syntax and types.
- \`cargo build --release\` — Build release .dylib library.

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

    FULL_PATH=$(cd "$TARGET_DIR" && pwd)
    echo ""
    echo "=================================================================="
    echo "  [✓] Plugin '$PLUGIN_NAME' successfully initialized!"
    echo "  Location: $FULL_PATH"
    echo "=================================================================="
    echo ""
    echo "To compile your native macOS plugin (.dylib) right now:"
    if [ "$TARGET_DIR" != "." ]; then
        echo "  cd $TARGET_DIR"
    fi
    echo "  cargo build --release"
    echo "=================================================================="
fi

