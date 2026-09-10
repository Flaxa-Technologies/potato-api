#!/usr/bin/env bash
# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - Linux
# ==============================================================================
set -e

echo "=================================================================="
echo "  PotatoMC Native Plugin Development Environment Setup (Linux)    "
echo "=================================================================="

# Determine sudo requirement
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
    SUDO="sudo"
fi

# 1. System Build Dependencies
echo "[1/4] Checking and installing system build dependencies..."
if command -v apt-get &> /dev/null; then
    $SUDO apt-get update -y
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential curl pkg-config libssl-dev
elif command -v pacman &> /dev/null; then
    $SUDO pacman -S --noconfirm base-devel curl pkgconf openssl
elif command -v dnf &> /dev/null; then
    $SUDO dnf groupinstall -y "Development Tools" && $SUDO dnf install -y curl pkgconf-pkg-config openssl-devel
else
    echo "[i] Custom Linux distribution detected. Ensure gcc/clang, make, and build essentials are present."
fi
echo "[✓] Build dependencies verified."

# 2. Check for Cargo / Rust in existing paths
echo "[2/4] Checking for existing Rust toolchain..."

if ! command -v cargo &> /dev/null; then
    for cargo_env in "$HOME/.cargo/env" "/usr/local/cargo/env" "/root/.cargo/env"; do
        if [ -f "$cargo_env" ]; then
            . "$cargo_env" 2>/dev/null || true
        fi
    done
    for cargo_bin in "$HOME/.cargo/bin" "/usr/local/cargo/bin" "/root/.cargo/bin"; do
        if [ -d "$cargo_bin" ]; then
            export PATH="$cargo_bin:$PATH"
        fi
    done
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
        echo "[i] Auto-installation cancelled."
        echo "Please install Rust manually from: https://rustup.rs/"
        echo "Then re-run this setup script."
        exit 0
    fi

    echo ""
    echo "[*] Proceeding with automatic Rust installation..."

    INSTALL_SUCCESS=false
    TMP_INIT="/tmp/rustup-init-$$.sh"

    echo "[i] Downloading rustup installer from https://sh.rustup.rs..."
    if curl --proto '=https' --tlsv1.2 -sSfL https://sh.rustup.rs -o "$TMP_INIT"; then
        if sh "$TMP_INIT" -y --default-toolchain stable --profile default; then
            INSTALL_SUCCESS=true
        fi
        rm -f "$TMP_INIT"
    fi

    # Fallback to distro package manager if rustup download failed
    if [ "$INSTALL_SUCCESS" = false ]; then
        echo "[!] rustup installation was unavailable. Attempting package manager fallback..."
        if command -v apt-get &> /dev/null; then
            $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y cargo rustc && INSTALL_SUCCESS=true
        elif command -v pacman &> /dev/null; then
            $SUDO pacman -S --noconfirm rust && INSTALL_SUCCESS=true
        elif command -v dnf &> /dev/null; then
            $SUDO dnf install -y cargo rust && INSTALL_SUCCESS=true
        fi
    fi

    # Reload environment
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env" 2>/dev/null || true
    fi
    export PATH="$HOME/.cargo/bin:$PATH"

    if command -v cargo &> /dev/null; then
        RUST_VER=$(cargo --version)
        echo "[✓] Successfully installed: $RUST_VER"
    else
        echo "[ERROR] Cargo installation could not be completed automatically."
        echo "Please install Rust manually via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
fi

# 3. Ensure stable toolchain
echo "[3/4] Checking Rust toolchain status..."
if command -v rustup &> /dev/null; then
    rustup default stable 2>/dev/null || true
    echo "[✓] Default toolchain set to stable."
fi

# 4. Interactive Scaffolding
echo "[4/4] Environment ready!"
echo "=================================================================="
echo "  PotatoMC Linux Native Plugin Development Environment is Ready!  "
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

    # Write Cargo.toml
    cat <<EOF > "$TARGET_DIR/Cargo.toml"
[package]
name = "$CRATE_NAME"
version = "0.1.0"
edition = "2024"
authors = ["$PLUGIN_AUTHOR"]
description = "Native Linux PotatoMC Plugin (.so)"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { git = "https://github.com/Flaxa-Technologies/potato-api" }
EOF

    # Write src/lib.rs with all Paper APIs
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
            .description("Official Paper-grade Native Linux PotatoMC Plugin (.so)")
    }

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME loaded on Linux!");
        let default_cfg = r#"# $PLUGIN_NAME Configuration
server:
  welcome_message: "<gradient:#00ffaa:#00aaff><bold>Welcome, {player}!</bold></gradient> Running on PotatoMC!"
  tab_header: "<aqua><bold>PotatoMC Linux Server</bold></aqua>"
  tab_footer: "<gray>Paper-grade Native Plugin (.so)</gray>"
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
        let tab_header = config.get_string_or("server.tab_header", "<aqua>PotatoMC</aqua>");
        let tab_footer = config.get_string_or("server.tab_footer", "<gray>Native Linux .so</gray>");
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

        // 2. BlockBreakEvent: prevent breaking bedrock
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
                if block.block_type == "minecraft:emerald_block" {
                    event.player.send_message("§a✨ You tapped an Emerald Block!");
                }
            }
        });

        // 4. Brigadier Commands
        let cmd = Command::tree("$CMD_NAME")
            .description("Command provided by $PLUGIN_NAME")
            .subcommand(
                Command::tree("greet")
                    .argument(Argument::word("target"))
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let target = ctx.get_string("target").unwrap_or("Friend");
                        let comp = Component::text("Hello, ")
                            .color(NamedTextColor::Aqua)
                            .append(Component::text(target).color(NamedTextColor::Gold).bold())
                            .append(Component::text(" from Linux native plugin!"));

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
                        item.set_custom_name("§b§lLinux Cleaver");
                        item.add_lore("§7Native Linux .so item");
                        item.add_enchantment("minecraft:sharpness", 5);

                        let mut pdc = PersistentDataContainer::new();
                        pdc.set_string("rpg:kernel", "Linux");
                        item.set_pdc(pdc);

                        ctx.sender().send_message(&format!(
                            "§aCreated item '{}' with PDC rarity: {:?}",
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
                            "§b§lLinux Cluster Guardian",
                            BossBarColor::Blue,
                            BossBarStyle::Notched12,
                        ).with_progress(0.90);

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
            setup_logger.info("Delayed 5-second task executed on Linux main thread.");
        });

        let timer_logger = context.logger().clone();
        let _ = context.scheduler().run_task_repeating(
            Duration::from_secs(60),
            Duration::from_secs(60),
            move || {
                timer_logger.debug("Periodic heartbeat tick.");
            },
        );

        let async_logger = context.logger().clone();
        std::thread::spawn(move || {
            async_logger.info("Async worker thread running on Linux thread pool!");
        });

        logger.info("$PLUGIN_NAME enabled successfully on Linux (.so)!");
        Ok(())
    }

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$PLUGIN_NAME disabled.");
        Ok(())
    }
}

potato_plugin!($STRUCT_NAME);
EOF

    # Write build.sh
    cat <<EOF > "$TARGET_DIR/build.sh"
#!/usr/bin/env bash
set -e
echo "Building $PLUGIN_NAME (.so)..."
cargo build --release
SO_FILE="target/release/lib${CRATE_NAME//-/_}.so"
if [ -f "\$SO_FILE" ]; then
    echo "[✓] Successfully built: \$SO_FILE"
    if [ -d "../../plugins" ]; then
        cp -f "\$SO_FILE" "../../plugins/"
        echo "Deployed to ../../plugins/"
    fi
fi
EOF
    chmod +x "$TARGET_DIR/build.sh"

    # Write Makefile
    cat <<EOF > "$TARGET_DIR/Makefile"
.PHONY: build release clean

release:
	cargo build --release

build:
	cargo build

clean:
	cargo clean
EOF

    # Write .gitignore
    cat <<EOF > "$TARGET_DIR/.gitignore"
/target/
Cargo.lock
*.so
*.dll
*.dylib
*.pdb
EOF

    # Write README.md
    cat <<EOF > "$TARGET_DIR/README.md"
# $PLUGIN_NAME

Official Paper-grade Native Linux Plugin for PotatoMC.

## Building
\`\`\`bash
cargo build --release
\`\`\`
Or run:
\`\`\`bash
./build.sh
\`\`\`
The compiled shared library will be generated at:
\`target/release/lib${CRATE_NAME//-/_}.so\`

Copy this \`.so\` file into your PotatoMC server's \`plugins/\` folder.
EOF

    FULL_PATH=$(cd "$TARGET_DIR" && pwd)
    echo ""
    echo "=================================================================="
    echo "  [✓] Plugin '$PLUGIN_NAME' successfully initialized!"
    echo "  Location: $FULL_PATH"
    echo "=================================================================="
    echo ""
    echo "To compile your native Linux plugin (.so) right now:"
    if [ "$TARGET_DIR" != "." ]; then
        echo "  cd $TARGET_DIR"
    fi
    echo "  cargo build --release"
    echo ""
    echo "Your compiled shared library will be produced at:"
    echo "  target/release/lib${CRATE_NAME//-/_}.so"
    echo "=================================================================="
else
    echo "=================================================================="
    echo "  Environment configured! Ready to build PotatoMC plugins.        "
    echo "=================================================================="
    echo "To initialize a plugin later:"
    echo "  curl -sSL https://raw.githubusercontent.com/Flaxa-Technologies/potato-api/main/scripts/create-plugin.sh | bash"
    echo "=================================================================="
fi

