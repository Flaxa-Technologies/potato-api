pub mod bossbar;
pub mod command;
pub mod config;
pub mod context;
pub mod entity;
pub mod event;
pub mod host;
pub mod player;
pub mod plugin;
pub mod scheduler;
pub mod text;
pub mod types;
pub mod world;

pub use bossbar::{BossBar, BossBarColor, BossBarStyle};
pub use command::{
    Argument, ArgumentType, Command, CommandContext, CommandError, CommandNode, CommandResult,
    CommandSender,
};
pub use config::Config;
pub use context::{Logger, PluginContext};
pub use entity::{Entity, LivingEntity};
pub use event::*;
pub use player::Player;
pub use plugin::{Plugin, PluginMetadata};
pub use scheduler::{Scheduler, TaskHandle};
pub use text::{Component, NamedTextColor, TextDecoration};
pub use types::{
    Block, Difficulty, EquipmentSlot, GameMode, HostInventory, Inventory, ItemStack, Location,
    PersistentDataContainer, Vector3,
};
pub use uuid::Uuid;
pub use world::World;

/// Public PotatoMC Plugin API Version constant.
/// Dynamic plugins must match this version to be loaded by the host.
pub const POTATO_API_VERSION: u32 = 1;

/// Macro to export the required dynamic library entrypoints for a PotatoMC native plugin.
#[macro_export]
macro_rules! potato_plugin {
    ($plugin_type:ident) => {
        #[unsafe(no_mangle)]
        pub static POTATO_API_VERSION: u32 = $crate::POTATO_API_VERSION;

        #[unsafe(no_mangle)]
        pub fn potato_create_plugin() -> Box<dyn $crate::Plugin> {
            Box::new($plugin_type::default())
        }
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_location_and_vector() {
        let loc1 = Location::new("minecraft:overworld", 0.0, 10.0, 0.0, 0.0, 0.0);
        let loc2 = Location::new("minecraft:overworld", 3.0, 10.0, 4.0, 90.0, 0.0);
        assert!((loc1.distance(&loc2) - 5.0).abs() < 0.001);
        assert_eq!(loc1.position(), Vector3::new(0.0, 10.0, 0.0));
    }

    #[test]
    fn test_itemstack_and_block() {
        let item = ItemStack::new("minecraft:diamond", 64)
            .with_name("Shiny Diamond")
            .with_lore(vec!["A rare gem".to_string()]);
        assert_eq!(item.amount, 64);
        assert_eq!(item.custom_name.as_deref(), Some("Shiny Diamond"));
        assert_eq!(item.lore.len(), 1);
        assert!(!item.is_empty());

        let empty_item = ItemStack::new("minecraft:air", 0);
        assert!(empty_item.is_empty());

        let block = Block::new("minecraft:stone", 1);
        assert_eq!(block.block_type, "minecraft:stone");
        assert!(!block.is_air());

        let air_block = Block::new("minecraft:air", 0);
        assert!(air_block.is_air());
    }

    #[test]
    fn test_enums() {
        assert_eq!(GameMode::Survival.name(), "survival");
        assert_eq!(GameMode::Creative.id(), 1);
        assert_eq!(GameMode::from_id(2), Some(GameMode::Adventure));

        assert_eq!(Difficulty::Hard.name(), "hard");
        assert_eq!(Difficulty::Peaceful.id(), 0);
        assert_eq!(Difficulty::from_id(2), Some(Difficulty::Normal));

        let _slot = EquipmentSlot::Helmet;
    }

    #[test]
    fn test_command_builder() {
        let cmd = Command::tree("test")
            .description("A test command")
            .permission("test.perm")
            .alias("t")
            .argument(Argument::integer("amount"))
            .executes(|ctx| {
                ctx.sender().send_message("ok");
                Ok(())
            });
        assert_eq!(cmd.name, "test");
        assert_eq!(cmd.description, "A test command");
        assert_eq!(cmd.permission.as_deref(), Some("test.perm"));
        assert_eq!(cmd.aliases, vec!["t"]);
        assert_eq!(cmd.arguments.len(), 1);
        assert!(cmd.executor.is_some());
    }

    #[test]
    fn test_event_ids() {
        assert_eq!(PlayerJoinEvent::EVENT_ID, 1);
        assert_eq!(PlayerQuitEvent::EVENT_ID, 2);
        assert_eq!(PlayerMoveEvent::EVENT_ID, 3);
        assert_eq!(PlayerInteractEvent::EVENT_ID, 4);
        assert_eq!(BlockBreakEvent::EVENT_ID, 5);
        assert_eq!(BlockPlaceEvent::EVENT_ID, 6);
        assert_eq!(EntitySpawnEvent::EVENT_ID, 7);
        assert_eq!(EntityDeathEvent::EVENT_ID, 8);
        assert_eq!(DamageEvent::EVENT_ID, 9);
        assert_eq!(PlayerChatEvent::EVENT_ID, 10);
        assert_eq!(PlayerCommandPreprocessEvent::EVENT_ID, 11);
        assert_eq!(PlayerDropItemEvent::EVENT_ID, 12);
        assert_eq!(PlayerItemConsumeEvent::EVENT_ID, 13);
        assert_eq!(PlayerRespawnEvent::EVENT_ID, 14);
        assert_eq!(PlayerTeleportEvent::EVENT_ID, 15);
        assert_eq!(PlayerGameModeChangeEvent::EVENT_ID, 16);
        assert_eq!(PlayerToggleSneakEvent::EVENT_ID, 17);
        assert_eq!(PlayerToggleSprintEvent::EVENT_ID, 18);
        assert_eq!(PlayerToggleFlightEvent::EVENT_ID, 19);
        assert_eq!(ServerListPingEvent::EVENT_ID, 22);
    }

    struct MockHostContext {
        logs: std::sync::Mutex<Vec<String>>,
        commands: std::sync::Mutex<Vec<CommandNode>>,
        listeners: std::sync::Mutex<std::collections::HashMap<u32, Vec<std::sync::Arc<dyn host::RawEventListener>>>>,
        cancelled_tasks: std::sync::Mutex<Vec<u64>>,
    }

    impl host::HostContext for MockHostContext {
        fn plugin_name(&self) -> &str { "mock_plugin" }
        fn log(&self, _level: host::LogLevel, message: &str) {
            self.logs.lock().unwrap().push(message.to_string());
        }
        fn run_task(&self, task: Box<dyn FnOnce() + Send>) { task(); }
        fn run_task_later(&self, _delay: u64, task: Box<dyn FnOnce() + Send>) -> u64 { task(); 42 }
        fn run_task_repeating(&self, _init: u64, _period: u64, mut task: Box<dyn FnMut() + Send>) -> u64 { task(); 43 }
        fn cancel_task(&self, task_id: u64) { self.cancelled_tasks.lock().unwrap().push(task_id); }
        fn register_event_listener(&self, event_id: u32, listener: std::sync::Arc<dyn host::RawEventListener>) {
            self.listeners.lock().unwrap().entry(event_id).or_default().push(listener);
        }
        fn register_command(&self, command: CommandNode) {
            self.commands.lock().unwrap().push(command);
        }
        fn get_player_by_uuid(&self, _uuid: &Uuid) -> Option<std::sync::Arc<dyn host::HostPlayer>> { None }
        fn get_player_by_name(&self, _name: &str) -> Option<std::sync::Arc<dyn host::HostPlayer>> { None }
        fn get_online_players(&self) -> Vec<std::sync::Arc<dyn host::HostPlayer>> { Vec::new() }
        fn get_world(&self, _name: &str) -> Option<std::sync::Arc<dyn host::HostWorld>> { None }
        fn get_worlds(&self) -> Vec<std::sync::Arc<dyn host::HostWorld>> { Vec::new() }
        fn data_folder(&self) -> std::path::PathBuf { std::path::PathBuf::from("plugins/mock_plugin") }
        fn broadcast(&self, message: &str) { self.logs.lock().unwrap().push(format!("[BROADCAST] {message}")); }
        fn server_version(&self) -> &str { "PotatoMC 0.1.0-mock" }
    }

    #[test]
    fn test_mock_plugin_context_workflow() {
        let mock_host = std::sync::Arc::new(MockHostContext {
            logs: std::sync::Mutex::new(Vec::new()),
            commands: std::sync::Mutex::new(Vec::new()),
            listeners: std::sync::Mutex::new(std::collections::HashMap::new()),
            cancelled_tasks: std::sync::Mutex::new(Vec::new()),
        });

        let ctx = PluginContext::new(mock_host.clone());
        ctx.logger().info("Hello from plugin");
        assert_eq!(mock_host.logs.lock().unwrap()[0], "Hello from plugin");

        // Event test
        let join_called = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
        let join_flag = join_called.clone();
        ctx.register_event(move |_event: &mut PlayerJoinEvent| {
            join_flag.store(true, std::sync::atomic::Ordering::SeqCst);
        });

        let listeners = mock_host.listeners.lock().unwrap();
        let join_listeners = listeners.get(&PlayerJoinEvent::EVENT_ID).unwrap();
        assert_eq!(join_listeners.len(), 1);

        struct DummyPlayer;
        impl host::HostPlayer for DummyPlayer {
            fn uuid(&self) -> Uuid { Uuid::nil() }
            fn name(&self) -> String { "Steve".to_string() }
            fn location(&self) -> Location { Location::new("overworld", 0.0, 0.0, 0.0, 0.0, 0.0) }
            fn world_id(&self) -> String { "overworld".to_string() }
            fn teleport(&self, _loc: &Location) -> bool { true }
            fn send_message(&self, _msg: &str) {}
            fn inventory(&self) -> std::sync::Arc<dyn HostInventory> {
                struct DummyInv;
                impl HostInventory for DummyInv {
                    fn get_held_item(&self) -> Option<ItemStack> { None }
                    fn set_held_item(&self, _i: Option<ItemStack>) {}
                    fn get_slot(&self, _s: usize) -> Option<ItemStack> { None }
                    fn set_slot(&self, _s: usize, _i: Option<ItemStack>) {}
                    fn get_equipment(&self, _slot: EquipmentSlot) -> Option<ItemStack> { None }
                    fn set_equipment(&self, _slot: EquipmentSlot, _i: Option<ItemStack>) {}
                    fn clear(&self) {}
                }
                std::sync::Arc::new(DummyInv)
            }
            fn has_permission(&self, _p: &str) -> bool { true }
            fn gamemode(&self) -> GameMode { GameMode::Survival }
            fn set_gamemode(&self, _mode: GameMode) {}
            fn health(&self) -> f32 { 20.0 }
            fn set_health(&self, _h: f32) {}
            fn max_health(&self) -> f32 { 20.0 }
            fn food_level(&self) -> u32 { 20 }
            fn set_food_level(&self, _f: u32) {}
            fn is_sneaking(&self) -> bool { false }
            fn is_sprinting(&self) -> bool { false }
            fn is_flying(&self) -> bool { false }
            fn set_flying(&self, _f: bool) {}
            fn can_fly(&self) -> bool { false }
            fn set_can_fly(&self, _c: bool) {}
            fn ping(&self) -> u32 { 10 }
            fn level(&self) -> i32 { 0 }
            fn set_level(&self, _l: i32) {}
            fn exp(&self) -> i32 { 0 }
            fn give_exp(&self, _e: i32) {}
            fn send_title(&self, _t: &str, _s: &str, _in: u32, _stay: u32, _out: u32) {}
            fn send_action_bar(&self, _m: &str) {}
            fn play_sound(&self, _s: &str, _v: f32, _p: f32) {}
            fn kick(&self, _r: &str) {}
            fn set_player_list_header_footer(&self, _h: &str, _f: &str) {}
        }

        let mut event = PlayerJoinEvent {
            player: Player::from_handle(std::sync::Arc::new(DummyPlayer)),
            join_message: Some("Welcome Steve!".to_string()),
            cancelled: false,
        };

        join_listeners[0].handle_raw(
            PlayerJoinEvent::EVENT_ID,
            (&mut event as *mut PlayerJoinEvent).cast::<()>(),
        );
        assert!(join_called.load(std::sync::atomic::Ordering::SeqCst));

        // Scheduler task handle cancellation
        let handle = ctx.scheduler().run_task_later(std::time::Duration::from_millis(100), || {});
        assert_eq!(handle.id, 42);
        handle.cancel();
        assert!(handle.is_cancelled());
        assert_eq!(mock_host.cancelled_tasks.lock().unwrap()[0], 42);
    }

    #[test]
    fn test_config_api() {
        let yaml = r#"
server:
  port: 25565
  motd: "A PotatoMC Server"
features:
  pvp: true
  rates: 1.5
tags:
  - alpha
  - beta
"#;
        let mut cfg = Config::from_yaml_str(yaml).unwrap();
        assert_eq!(cfg.get_int("server.port"), Some(25565));
        assert_eq!(cfg.get_string("server.motd"), Some("A PotatoMC Server".to_string()));
        assert_eq!(cfg.get_bool("features.pvp"), Some(true));
        assert_eq!(cfg.get_float("features.rates"), Some(1.5));
        assert_eq!(cfg.get_string_list("tags"), vec!["alpha", "beta"]);

        cfg.set_string("server.motd", "Updated Potato Server");
        assert_eq!(cfg.get_string("server.motd"), Some("Updated Potato Server".to_string()));
    }

    #[test]
    fn test_text_component_and_minimessage() {
        let comp = Component::text("Hello ")
            .color(NamedTextColor::Green)
            .bold()
            .append(Component::text("World").color(NamedTextColor::Gold));

        let legacy = comp.to_legacy_string();
        assert!(legacy.contains("§a"));
        assert!(legacy.contains("§l"));
        assert!(legacy.contains("§6"));
        assert_eq!(comp.to_plain_text(), "Hello World");

        let parsed_amp = Component::from_legacy_ampersand("&cRed &eYellow");
        assert_eq!(parsed_amp.to_plain_text(), "Red Yellow");

        let mini = Component::from_mini_message("<gold><bold>Winner!</bold></gold>");
        assert_eq!(mini.to_plain_text(), "Winner!");
    }

    #[test]
    fn test_bossbar_api() {
        let bar = BossBar::new("Ender Dragon", BossBarColor::Purple, BossBarStyle::Notched10)
            .with_progress(0.75);
        assert_eq!(bar.title, "Ender Dragon");
        assert_eq!(bar.color, BossBarColor::Purple);
        assert_eq!(bar.style, BossBarStyle::Notched10);
        assert!((bar.progress - 0.75).abs() < 0.001);
    }

    #[test]
    fn test_persistent_data_container_and_enchantments() {
        let mut item = ItemStack::new("minecraft:diamond_sword", 1)
            .with_enchantment("minecraft:sharpness", 5)
            .with_enchantment("minecraft:unbreaking", 3);
        assert_eq!(item.get_enchantment("minecraft:sharpness"), Some(5));
        assert_eq!(item.get_enchantment("minecraft:unbreaking"), Some(3));
        assert!(item.has_enchantment("minecraft:sharpness"));
        assert!(!item.has_enchantment("minecraft:fire_aspect"));

        item.persistent_data.set_string("custom_id", "mythic_blade");
        item.persistent_data.set_int("kill_count", 42);
        assert_eq!(item.persistent_data.get_string("custom_id"), Some("mythic_blade"));
        assert_eq!(item.persistent_data.get_int("kill_count"), Some(42));
        assert!(item.persistent_data.has("custom_id"));
        assert!(!item.persistent_data.has("unknown_key"));
    }
}
