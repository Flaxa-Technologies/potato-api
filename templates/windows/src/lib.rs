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

/// Main plugin structure for Windows. Must implement `Default`.
#[derive(Default)]
pub struct MyWindowsPlugin;

impl Plugin for MyWindowsPlugin {
    /// Declare plugin identity, version, author, and description.
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("MyWindowsPlugin", "1.0.0")
            .author("Flaxa Technologies")
            .description("Official Paper-Grade PotatoMC Native Plugin for Windows (.dll)")
    }

    /// Called when the dynamic library (.dll) is initially loaded by PotatoMC.
    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("MyWindowsPlugin loaded on Windows host!");

        // Set up default config.yml if it does not already exist
        let default_config = r#"# MyWindowsPlugin Configuration
server:
  welcome_message: "<gradient:#ffaa00:#ff5555><bold>Welcome, {player}!</bold></gradient> Enjoy your stay on PotatoMC!"
  tab_header: "<gold><bold>PotatoMC Windows Server</bold></gold>"
  tab_footer: "<gray>Powered by Potato Native API (.dll)</gray>"
features:
  protect_bedrock: true
  bossbar_enabled: true
"#;
        let _ = context.save_default_config(default_config);
        Ok(())
    }

    /// Called when the plugin is enabled and ready to register commands, events, and schedulers.
    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        let logger = context.logger();
        logger.info("MyWindowsPlugin enabling...");

        let config = context.config();
        let welcome_template = config.get_string_or(
            "server.welcome_message",
            "Welcome, {player}! Enjoy your stay on PotatoMC!",
        );
        let tab_header = config.get_string_or("server.tab_header", "<gold>PotatoMC</gold>");
        let tab_footer = config.get_string_or("server.tab_footer", "<gray>Native DLL Plugin</gray>");
        let protect_bedrock = config.get_bool_or("features.protect_bedrock", true);

        // -------------------------------------------------------------
        // 1. EVENT SYSTEM (Paper / Bukkit Publisher-Observer Pattern)
        // -------------------------------------------------------------

        // 1a. PlayerJoinEvent: fires when a player connects and enters world
        let join_template = welcome_template.clone();
        let header_str = tab_header.clone();
        let footer_str = tab_footer.clone();
        context.register_event(move |event: &mut PlayerJoinEvent| {
            let player = &event.player;
            let player_name = player.name();

            // Format welcome message using Adventure MiniMessage
            let formatted = join_template.replace("{player}", &player_name);
            let component = Component::from_mini_message(&formatted);
            player.send_component(&component);

            // Update client tab list header and footer (Paper Player#setPlayerListHeaderFooter)
            let h = Component::from_mini_message(&header_str);
            let f = Component::from_mini_message(&footer_str);
            player.set_player_list_header_footer(&h.to_legacy_string(), &f.to_legacy_string());
        });

        // 1b. BlockBreakEvent: fires when a block is broken (Demonstrates Cancellable)
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

        // 1c. PlayerInteractEvent: fires when player clicks block or air
        context.register_event(move |event: &mut PlayerInteractEvent| {
            if let Some(ref block) = event.clicked_block {
                if block.block_type == "minecraft:diamond_block" {
                    event.player.send_message("§b✨ You tapped a Diamond Block!");
                }
            }
        });

        // 1d. PlayerChatEvent: fires when player chats
        context.register_event(move |event: &mut PlayerChatEvent| {
            if event.message.contains("lag") {
                event.player.send_message("§ePotatoMC is running at optimal 20.0 TPS native speed!");
            }
        });

        // -------------------------------------------------------------
        // 2. COMMAND API (Brigadier-style fluent trees)
        // -------------------------------------------------------------
        let cmd = Command::tree("winplugin")
            .description("Official command from MyWindowsPlugin")
            .alias("wp")
            .subcommand(
                Command::tree("greet")
                    .description("Greets a player or custom name")
                    .argument(Argument::word("target"))
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let target = ctx.get_string("target").unwrap_or("Friend");
                        let comp = Component::text("Hello, ")
                            .color(NamedTextColor::Yellow)
                            .append(Component::text(target).color(NamedTextColor::Green).bold())
                            .append(Component::text(" from Windows .dll plugin!"));

                        match ctx.sender() {
                            CommandSender::Player(p) => p.send_component(&comp),
                            CommandSender::Console(c) => c.send_message(&comp.to_plain_text()),
                        }
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("item")
                    .description("Demonstrates ItemStack, PDC, and Enchantments")
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let mut sword = ItemStack::new("minecraft:diamond_sword", 1);
                        sword.set_custom_name("§6§lExcalibur of the North");
                        sword.add_lore("§7Forged in native Rust code");
                        sword.add_lore("§8PDC Tag: rarity=LEGENDARY");
                        sword.add_enchantment("minecraft:sharpness", 5);
                        sword.add_enchantment("minecraft:unbreaking", 3);

                        // Attach Bukkit/Paper Persistent Data Container (PDC)
                        let mut pdc = PersistentDataContainer::new();
                        pdc.set_string("rpg:rarity", "LEGENDARY");
                        pdc.set_int("rpg:power_rating", 9001);
                        pdc.set_bytes("rpg:signature", vec![0xDE, 0xAD, 0xBE, 0xEF]);
                        sword.set_pdc(pdc);

                        ctx.sender().send_message(&format!(
                            "§aCreated custom item '{}' (PDC rarity: {:?}, sharpness: {:?})",
                            sword.custom_name.as_deref().unwrap_or(""),
                            sword.pdc().get_string("rpg:rarity"),
                            sword.get_enchantment_level("minecraft:sharpness"),
                        ));
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("bossbar")
                    .description("Demonstrates Adventure BossBar creation")
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let bar = BossBar::new(
                            "§6§lWindows Core Titan",
                            BossBarColor::Yellow,
                            BossBarStyle::Notched10,
                        ).with_progress(0.85);

                        ctx.sender().send_message(&format!(
                            "§aCreated BossBar '{}' with progress {:.0}%",
                            bar.title, bar.progress * 100.0
                        ));
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("broadcast")
                    .description("Broadcast an Adventure MiniMessage to the whole server")
                    .argument(Argument::string("message"))
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let msg = ctx.get_string("message").unwrap_or("Default message");
                        let formatted = Component::from_mini_message(&format!(
                            "<dark_purple>[Announcement]</dark_purple> <white>{}</white>",
                            msg
                        ));
                        ctx.sender().send_message(&format!("[Broadcast] {}", formatted.to_legacy_string()));
                        Ok(())
                    }),
            )
            .executes(|ctx: &CommandContext| -> CommandResult {
                ctx.sender().send_message("§eUsage: /winplugin <greet <name> | item | bossbar | broadcast <msg>>");
                Ok(())
            });

        context.register_command(cmd);

        // -------------------------------------------------------------
        // 3. SCHEDULER (Sync Delayed, Repeating, and Async Concurrency)
        // -------------------------------------------------------------

        // 3a. Delayed task: Runs once 5 seconds later
        let setup_logger = context.logger().clone();
        context.scheduler().run_task_later(Duration::from_secs(5), move || {
            setup_logger.info("Delayed 5-second task executed on main thread.");
        });

        // 3b. Repeating task: Runs every 60 seconds
        let timer_logger = context.logger().clone();
        let _repeating_id = context.scheduler().run_task_repeating(
            Duration::from_secs(60),
            Duration::from_secs(60),
            move || {
                timer_logger.debug("Windows plugin periodic heartbeat tick.");
            },
        );

        // 3c. Off-thread Async Task: For non-blocking I/O or database queries
        let async_logger = context.logger().clone();
        std::thread::spawn(move || {
            async_logger.info("Async background worker pool running off the main thread!");
        });

        logger.info("MyWindowsPlugin enabled successfully on Windows (.dll)!");
        Ok(())
    }

    /// Called on server shutdown or when the plugin is disabled.
    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("MyWindowsPlugin disabled.");
        Ok(())
    }
}

// -----------------------------------------------------------------
// EXPORT NATIVE ENTRYPOINT
// Exposes the required C-ABI symbol `potato_create_plugin` and API version.
// -----------------------------------------------------------------
potato_plugin!(MyWindowsPlugin);
