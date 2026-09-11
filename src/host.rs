use std::sync::Arc;
use uuid::Uuid;

use crate::types::{Block, Difficulty, GameMode, ItemStack, Location, PotionEffect, Vector3};
pub use crate::types::HostInventory;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogLevel {
    Trace,
    Debug,
    Info,
    Warn,
    Error,
}

pub trait HostPlayer: Send + Sync {
    fn uuid(&self) -> Uuid;
    fn name(&self) -> String;
    fn location(&self) -> Location;
    fn world_id(&self) -> String;
    fn teleport(&self, location: &Location) -> bool;
    fn send_message(&self, message: &str);
    fn inventory(&self) -> Arc<dyn HostInventory>;
    fn has_permission(&self, permission: &str) -> bool;

    fn gamemode(&self) -> GameMode;
    fn set_gamemode(&self, mode: GameMode);
    fn health(&self) -> f32;
    fn set_health(&self, health: f32);
    fn max_health(&self) -> f32;
    fn food_level(&self) -> u32;
    fn set_food_level(&self, food: u32);
    fn is_sneaking(&self) -> bool;
    fn is_sprinting(&self) -> bool;
    fn is_flying(&self) -> bool;
    fn set_flying(&self, flying: bool);
    fn can_fly(&self) -> bool;
    fn set_can_fly(&self, can_fly: bool);
    fn ping(&self) -> u32;
    fn level(&self) -> i32;
    fn set_level(&self, level: i32);
    fn exp(&self) -> i32;
    fn give_exp(&self, exp: i32);
    fn send_title(&self, title: &str, subtitle: &str, fade_in_ticks: u32, stay_ticks: u32, fade_out_ticks: u32);
    fn send_action_bar(&self, message: &str);
    fn play_sound(&self, sound: &str, volume: f32, pitch: f32);
    fn kick(&self, reason: &str);
    fn set_player_list_header_footer(&self, header: &str, footer: &str);

    fn drop_item(&self, _item: &ItemStack) {}
    fn give_item(&self, _item: &ItemStack) -> bool { false }
    fn open_gui(&self, _title: &str, _size: usize, _items: &[(usize, ItemStack)], _allow_grab: bool, _allow_put: bool) -> u8 { 0 }
    fn close_inventory(&self) {}
    fn add_potion_effect(&self, _effect: &PotionEffect) {}
    fn remove_potion_effect(&self, _effect_type: &str) {}
    fn clear_potion_effects(&self) {}
    fn has_potion_effect(&self, _effect_type: &str) -> bool { false }
    fn spawn_particle(&self, _particle: &str, _location: &Location, _count: u32, _offset_x: f64, _offset_y: f64, _offset_z: f64, _speed: f32) {}
}

pub trait HostWorld: Send + Sync {
    fn identity(&self) -> String;
    fn get_block(&self, x: i32, y: i32, z: i32) -> Option<Block>;
    fn set_block(&self, x: i32, y: i32, z: i32, block: &Block) -> bool;
    fn spawn_entity(&self, entity_type: &str, location: &Location) -> Result<Arc<dyn HostEntity>, String>;
    fn player_lookup(&self, name: &str) -> Option<Arc<dyn HostPlayer>>;
    fn players(&self) -> Vec<Arc<dyn HostPlayer>>;

    fn time(&self) -> u64;
    fn set_time(&self, time: u64);
    fn is_raining(&self) -> bool;
    fn set_storm(&self, storm: bool);
    fn difficulty(&self) -> Difficulty;
    fn set_difficulty(&self, diff: Difficulty);
    fn create_explosion(&self, x: f64, y: f64, z: f64, power: f32, fire: bool, break_blocks: bool);
    fn play_sound(&self, location: &Location, sound: &str, volume: f32, pitch: f32);
    fn broadcast_message(&self, message: &str);

    fn drop_item(&self, _location: &Location, _item: &ItemStack) {}
    fn drop_item_naturally(&self, location: &Location, item: &ItemStack) {
        self.drop_item(location, item);
    }
    fn break_block(&self, x: i32, y: i32, z: i32, _drop_items: bool) -> bool {
        self.set_block(x, y, z, &Block::new("minecraft:air", 0))
    }
    fn spawn_particle(&self, _particle: &str, _location: &Location, _count: u32, _offset_x: f64, _offset_y: f64, _offset_z: f64, _speed: f32) {}
}

pub trait HostEntity: Send + Sync {
    fn uuid(&self) -> Uuid;
    fn entity_type(&self) -> String;
    fn location(&self) -> Location;
    fn teleport(&self, location: &Location) -> bool;
    fn velocity(&self) -> Vector3;
    fn set_velocity(&self, velocity: &Vector3);
    fn remove(&self);
    fn as_living(&self) -> Option<Arc<dyn HostLivingEntity>>;

    fn is_on_ground(&self) -> bool;
    fn custom_name(&self) -> Option<String>;
    fn set_custom_name(&self, name: Option<&str>);
    fn fire_ticks(&self) -> i32;
    fn set_fire_ticks(&self, ticks: i32);
    fn damage(&self, amount: f32);
}

pub trait HostLivingEntity: Send + Sync {
    fn base_entity(&self) -> Arc<dyn HostEntity>;
    fn health(&self) -> f32;
    fn set_health(&self, health: f32);
    fn max_health(&self) -> f32;
}

pub trait HostConsole: Send + Sync {
    fn send_message(&self, message: &str);
}

pub trait RawEventListener: Send + Sync {
    fn handle_raw(&self, event_id: u32, event_ptr: *mut ());
}

pub trait HostContext: Send + Sync {
    fn plugin_name(&self) -> &str;
    fn log(&self, level: LogLevel, message: &str);

    fn run_task(&self, task: Box<dyn FnOnce() + Send>);
    fn run_task_later(&self, delay_millis: u64, task: Box<dyn FnOnce() + Send>) -> u64;
    fn run_task_repeating(&self, initial_delay_millis: u64, period_millis: u64, task: Box<dyn FnMut() + Send>) -> u64;
    fn cancel_task(&self, task_id: u64);

    fn register_event_listener(&self, event_id: u32, listener: Arc<dyn RawEventListener>);
    fn register_command(&self, command: crate::command::CommandNode);

    fn get_player_by_uuid(&self, uuid: &Uuid) -> Option<Arc<dyn HostPlayer>>;
    fn get_player_by_name(&self, name: &str) -> Option<Arc<dyn HostPlayer>>;
    fn get_online_players(&self) -> Vec<Arc<dyn HostPlayer>>;
    fn get_world(&self, name: &str) -> Option<Arc<dyn HostWorld>>;
    fn get_worlds(&self) -> Vec<Arc<dyn HostWorld>>;
    fn data_folder(&self) -> std::path::PathBuf;

    fn broadcast(&self, message: &str);
    fn server_version(&self) -> &str;

    fn get_tps(&self) -> f64 { 20.0 }
    fn max_players(&self) -> u32 { 100 }
    fn dispatch_command(&self, _command: &str) -> bool { false }
}
