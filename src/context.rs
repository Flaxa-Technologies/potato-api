use std::sync::Arc;
use uuid::Uuid;

use crate::command::CommandNode;
use crate::event::{Event, EventHandler};
use crate::host::{HostContext, LogLevel, RawEventListener};
use crate::player::Player;
use crate::scheduler::Scheduler;
use crate::world::World;

/// Lightweight logger utility for plugins.
#[derive(Clone)]
pub struct Logger {
    host: Arc<dyn HostContext>,
}

impl Logger {
    pub fn info(&self, msg: impl std::fmt::Display) {
        self.host.log(LogLevel::Info, &msg.to_string());
    }

    pub fn warn(&self, msg: impl std::fmt::Display) {
        self.host.log(LogLevel::Warn, &msg.to_string());
    }

    pub fn error(&self, msg: impl std::fmt::Display) {
        self.host.log(LogLevel::Error, &msg.to_string());
    }

    pub fn debug(&self, msg: impl std::fmt::Display) {
        self.host.log(LogLevel::Debug, &msg.to_string());
    }

    pub fn trace(&self, msg: impl std::fmt::Display) {
        self.host.log(LogLevel::Trace, &msg.to_string());
    }
}

/// The core interaction context passed to a plugin during its lifecycle.
#[derive(Clone)]
pub struct PluginContext {
    host: Arc<dyn HostContext>,
    scheduler: Scheduler,
    logger: Logger,
}

impl PluginContext {
    pub fn new(host: Arc<dyn HostContext>) -> Self {
        let scheduler = Scheduler::new(host.clone());
        let logger = Logger { host: host.clone() };
        Self {
            host,
            scheduler,
            logger,
        }
    }

    /// Returns the name of the active plugin.
    pub fn plugin_name(&self) -> &str {
        self.host.plugin_name()
    }

    /// Accesses the plugin logger.
    pub fn logger(&self) -> &Logger {
        &self.logger
    }

    /// Accesses the task scheduler.
    pub fn scheduler(&self) -> &Scheduler {
        &self.scheduler
    }

    /// Registers a new command with the server.
    pub fn register_command(&self, command: CommandNode) {
        self.host.register_command(command);
    }

    /// Registers an event handler for a specific event type.
    pub fn register_event<E: Event, H: EventHandler<E>>(&self, handler: H) {
        let listener = Arc::new(EventAdapter {
            handler,
            _phantom: std::marker::PhantomData,
        });
        self.host.register_event_listener(E::EVENT_ID, listener);
    }

    /// Finds an online player by their UUID.
    pub fn get_player(&self, uuid: &Uuid) -> Option<Player> {
        self.host.get_player_by_uuid(uuid).map(Player::from_handle)
    }

    /// Finds an online player by their username.
    pub fn get_player_by_name(&self, name: &str) -> Option<Player> {
        self.host.get_player_by_name(name).map(Player::from_handle)
    }

    /// Returns a list of all currently connected players across all worlds.
    pub fn get_online_players(&self) -> Vec<Player> {
        self.host
            .get_online_players()
            .into_iter()
            .map(Player::from_handle)
            .collect()
    }

    /// Looks up a world by its identifier (e.g. "minecraft:overworld").
    pub fn get_world(&self, name: &str) -> Option<World> {
        self.host.get_world(name).map(World::from_handle)
    }

    /// Returns all worlds loaded on the server.
    pub fn get_worlds(&self) -> Vec<World> {
        self.host
            .get_worlds()
            .into_iter()
            .map(World::from_handle)
            .collect()
    }

    /// Returns the dedicated data folder for this plugin (e.g. `plugins/MyPlugin/`).
    pub fn data_folder(&self) -> std::path::PathBuf {
        self.host.data_folder()
    }

    /// Loads the plugin's `config.yml` configuration file, or an empty config if missing.
    pub fn config(&self) -> crate::config::Config {
        let path = self.data_folder().join("config.yml");
        crate::config::Config::from_file(&path).unwrap_or_default()
    }

    /// Saves the plugin configuration to `config.yml`.
    pub fn save_config(&self, config: &crate::config::Config) -> Result<(), String> {
        let path = self.data_folder().join("config.yml");
        config.save(path)
    }

    /// Saves the default configuration string if `config.yml` does not yet exist.
    pub fn save_default_config(&self, default_content: &str) -> Result<crate::config::Config, String> {
        let path = self.data_folder().join("config.yml");
        if !path.exists() {
            if let Some(parent) = path.parent() {
                let _ = std::fs::create_dir_all(parent);
            }
            std::fs::write(&path, default_content).map_err(|e| format!("Failed to write default config: {e}"))?;
        }
        crate::config::Config::from_file(&path)
    }

    /// Broadcasts a chat message to all connected players across the entire server.
    pub fn broadcast(&self, message: &str) {
        self.host.broadcast(message);
    }

    /// Broadcasts a rich Adventure text component to all connected players across the entire server.
    pub fn broadcast_component(&self, component: &crate::text::Component) {
        self.broadcast(&component.to_legacy_string());
    }

    /// Returns the active server implementation and version string.
    pub fn server_version(&self) -> &str {
        self.host.server_version()
    }
}

struct EventAdapter<E: Event, H: EventHandler<E>> {
    handler: H,
    _phantom: std::marker::PhantomData<E>,
}

impl<E: Event, H: EventHandler<E>> RawEventListener for EventAdapter<E, H> {
    fn handle_raw(&self, event_id: u32, event_ptr: *mut ()) {
        if event_id == E::EVENT_ID {
            // SAFETY: Verified event_id matches this adapter's registered event type E.
            let event = unsafe { &mut *(event_ptr.cast::<E>()) };
            self.handler.handle(event);
        }
    }
}
