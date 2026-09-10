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

echo "[✓] Plugin $PLUGIN_NAME created successfully!"
echo "To build: cd $PLUGIN_NAME && cargo build --release"
