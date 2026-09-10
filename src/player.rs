use std::sync::Arc;
use uuid::Uuid;

use crate::host::HostPlayer;
use crate::types::{GameMode, Inventory, Location};

/// Safe, high-level abstraction representing an online player on the PotatoMC server.
#[derive(Clone)]
pub struct Player {
    pub(crate) handle: Arc<dyn HostPlayer>,
}

impl Player {
    pub fn from_handle(handle: Arc<dyn HostPlayer>) -> Self {
        Self { handle }
    }

    pub fn inner(&self) -> &Arc<dyn HostPlayer> {
        &self.handle
    }

    /// Returns the unique UUID of this player.
    pub fn uuid(&self) -> Uuid {
        self.handle.uuid()
    }

    /// Returns the player's username.
    pub fn name(&self) -> String {
        self.handle.name()
    }

    /// Returns the current location of the player.
    pub fn location(&self) -> Location {
        self.handle.location()
    }

    /// Returns the world identifier (e.g. "minecraft:overworld") the player is currently in.
    pub fn world_id(&self) -> String {
        self.handle.world_id()
    }

    /// Teleports the player to the specified target location.
    pub fn teleport(&self, location: &Location) -> bool {
        self.handle.teleport(location)
    }

    /// Sends a system chat message to the player.
    pub fn send_message(&self, message: &str) {
        self.handle.send_message(message);
    }

    /// Accesses the player's inventory.
    pub fn inventory(&self) -> Inventory {
        Inventory::from_handle(self.handle.inventory())
    }

    /// Checks whether the player has a specific permission node.
    pub fn has_permission(&self, permission: &str) -> bool {
        self.handle.has_permission(permission)
    }

    /// Returns the player's current game mode.
    pub fn gamemode(&self) -> GameMode {
        self.handle.gamemode()
    }

    /// Sets the player's game mode.
    pub fn set_gamemode(&self, mode: GameMode) {
        self.handle.set_gamemode(mode);
    }

    /// Returns the player's current health points.
    pub fn health(&self) -> f32 {
        self.handle.health()
    }

    /// Sets the player's current health points.
    pub fn set_health(&self, health: f32) {
        self.handle.set_health(health);
    }

    /// Returns the player's maximum health points.
    pub fn max_health(&self) -> f32 {
        self.handle.max_health()
    }

    /// Returns the player's current food level (0-20).
    pub fn food_level(&self) -> u32 {
        self.handle.food_level()
    }

    /// Sets the player's food level (0-20).
    pub fn set_food_level(&self, food: u32) {
        self.handle.set_food_level(food);
    }

    /// Checks whether the player is sneaking.
    pub fn is_sneaking(&self) -> bool {
        self.handle.is_sneaking()
    }

    /// Checks whether the player is sprinting.
    pub fn is_sprinting(&self) -> bool {
        self.handle.is_sprinting()
    }

    /// Checks whether the player is currently flying.
    pub fn is_flying(&self) -> bool {
        self.handle.is_flying()
    }

    /// Sets whether the player is flying.
    pub fn set_flying(&self, flying: bool) {
        self.handle.set_flying(flying);
    }

    /// Checks whether the player has permission/ability to fly.
    pub fn can_fly(&self) -> bool {
        self.handle.can_fly()
    }

    /// Sets whether the player is allowed to fly.
    pub fn set_can_fly(&self, can_fly: bool) {
        self.handle.set_can_fly(can_fly);
    }

    /// Returns the player's network ping latency in milliseconds.
    pub fn ping(&self) -> u32 {
        self.handle.ping()
    }

    /// Returns the player's current experience level.
    pub fn level(&self) -> i32 {
        self.handle.level()
    }

    /// Sets the player's experience level.
    pub fn set_level(&self, level: i32) {
        self.handle.set_level(level);
    }

    /// Returns the player's total experience points.
    pub fn exp(&self) -> i32 {
        self.handle.exp()
    }

    /// Adds experience points to the player.
    pub fn give_exp(&self, exp: i32) {
        self.handle.give_exp(exp);
    }

    /// Displays a title and subtitle on the player's screen with fade timing.
    pub fn send_title(&self, title: &str, subtitle: &str, fade_in_ticks: u32, stay_ticks: u32, fade_out_ticks: u32) {
        self.handle.send_title(title, subtitle, fade_in_ticks, stay_ticks, fade_out_ticks);
    }

    /// Displays an action bar message above the player's hotbar.
    pub fn send_action_bar(&self, message: &str) {
        self.handle.send_action_bar(message);
    }

    /// Plays a sound effect to the player.
    pub fn play_sound(&self, sound: &str, volume: f32, pitch: f32) {
        self.handle.play_sound(sound, volume, pitch);
    }

    /// Disconnects the player with a custom kick message.
    pub fn kick(&self, reason: &str) {
        self.handle.kick(reason);
    }

    /// Sets the player's tab list header and footer text.
    pub fn set_player_list_header_footer(&self, header: &str, footer: &str) {
        self.handle.set_player_list_header_footer(header, footer);
    }

    /// Sends a rich Adventure text component to the player.
    pub fn send_component(&self, component: &crate::text::Component) {
        self.send_message(&component.to_legacy_string());
    }

    /// Sends a rich Adventure text action bar to the player.
    pub fn send_action_bar_component(&self, component: &crate::text::Component) {
        self.send_action_bar(&component.to_legacy_string());
    }

    /// Sends a rich Adventure text title & subtitle with animation timings to the player.
    pub fn send_title_components(
        &self,
        title: &crate::text::Component,
        subtitle: &crate::text::Component,
        fade_in_ticks: u32,
        stay_ticks: u32,
        fade_out_ticks: u32,
    ) {
        self.send_title(
            &title.to_legacy_string(),
            &subtitle.to_legacy_string(),
            fade_in_ticks,
            stay_ticks,
            fade_out_ticks,
        );
    }
}

impl std::fmt::Debug for Player {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Player")
            .field("uuid", &self.uuid())
            .field("name", &self.name())
            .field("location", &self.location())
            .finish()
    }
}

impl PartialEq for Player {
    fn eq(&self, other: &Self) -> bool {
        self.uuid() == other.uuid()
    }
}

impl Eq for Player {}

impl std::hash::Hash for Player {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.uuid().hash(state);
    }
}
