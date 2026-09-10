# Event System & Cancellation

The PotatoMC event system implements a type-safe publisher/observer pattern mirroring Bukkit/Paper.

---

## 1. Registering Event Handlers

Register event listeners in `on_enable()` via `context.register_event(...)`:

```rust
use potato_api::event::{PlayerJoinEvent, BlockBreakEvent, Cancellable};
use potato_api::text::Component;

// 1. Listen to player joins
context.register_event(|event: &mut PlayerJoinEvent| {
    let name = event.player.name();
    let comp = Component::from_mini_message(&format!("<yellow>Welcome, <gold>{}</gold>!</yellow>", name));
    event.player.send_component(&comp);
});

// 2. Prevent breaking bedrock
context.register_event(|event: &mut BlockBreakEvent| {
    if event.block.block_type == "minecraft:bedrock" {
        event.set_cancelled(true);
        if let Some(ref player) = event.player {
            player.send_message("§cBedrock is indestructible!");
        }
    }
});
```

---

## 2. Event Priorities

Event listeners execute in strict priority order. The earlier an event handler executes, the sooner it can inspect or cancel an event:

1. `EventPriority::Lowest` — First to observe, useful for low-level modifications.
2. `EventPriority::Low`
3. `EventPriority::Normal` (Default)
4. `EventPriority::High`
5. `EventPriority::Highest` — Runs right before action confirmation.
6. `EventPriority::Monitor` — Read-only observation; actions MUST NOT be altered here.

---

## 3. The `Cancellable` Trait

Events that can be prevented implement the `Cancellable` trait:

```rust
pub trait Cancellable {
    fn is_cancelled(&self) -> bool;
    fn set_cancelled(&mut self, cancelled: bool);
}
```

Calling `event.set_cancelled(true)` instructs PotatoMC to abort the underlying action (e.g. block breaking, teleportation, player chat, inventory interaction).

---

## 4. Complete 26-Event Catalog

| ID | Event Struct | Cancellable | Description & Fields |
|---|---|:---:|---|
| **1** | `ServerStartedEvent` | No | Server is ready and accepting connections. |
| **2** | `ServerStoppingEvent` | No | Server is initiating shutdown sequence. |
| **3** | `PlayerJoinEvent` | No | Player spawned in world: `player: Player`. |
| **4** | `PlayerQuitEvent` | No | Player disconnected: `player: Player`. |
| **5** | `PlayerChatEvent` | **Yes** | Player sent message: `player: Player`, `message: String`. |
| **6** | `PlayerMoveEvent` | **Yes** | Player movement: `player: Player`, `from: Location`, `to: Location`. |
| **7** | `PlayerInteractEvent` | **Yes** | Player click: `player: Player`, `clicked_block: Option<Block>`, `action: String`. |
| **8** | `PlayerTeleportEvent` | **Yes** | Teleportation: `player: Player`, `from: Location`, `to: Location`. |
| **9** | `PlayerToggleFlightEvent` | **Yes** | Flight state toggled: `player: Player`, `is_flying: bool`. |
| **10** | `PlayerToggleSneakEvent` | **Yes** | Sneak state toggled: `player: Player`, `is_sneaking: bool`. |
| **11** | `PlayerToggleSprintEvent` | **Yes** | Sprint state toggled: `player: Player`, `is_sprinting: bool`. |
| **12** | `PlayerRespawnEvent` | No | Player clicked respawn: `player: Player`, `respawn_location: Location`. |
| **13** | `BlockBreakEvent` | **Yes** | Block broken: `player: Option<Player>`, `block: Block`. |
| **14** | `BlockPlaceEvent` | **Yes** | Block placed: `player: Player`, `block: Block`, `placed_against: Option<Block>`. |
| **15** | `EntityDamageEvent` | **Yes** | Entity damaged: `entity: Entity`, `damage: f32`, `cause: String`. |
| **16** | `EntityDeathEvent` | No | Entity killed: `entity: Entity`, `dropped_items: Vec<ItemStack>`. |
| **17** | `EntitySpawnEvent` | **Yes** | Entity spawning: `entity: Entity`, `location: Location`. |
| **18** | `ItemDropEvent` | **Yes** | Item dropped by player: `player: Player`, `item: ItemStack`. |
| **19** | `ItemPickupEvent` | **Yes** | Item collected: `player: Player`, `item: ItemStack`. |
| **20** | `InventoryOpenEvent` | **Yes** | Player opened inventory: `player: Player`, `title: String`. |
| **21** | `InventoryCloseEvent` | No | Player closed inventory: `player: Player`. |
| **22** | `InventoryClickEvent` | **Yes** | Player clicked slot: `player: Player`, `slot: usize`, `click_type: String`. |
| **23** | `ChunkLoadEvent` | No | Chunk loaded into memory: `x: i32`, `z: i32`, `world: String`. |
| **24** | `ChunkUnloadEvent` | **Yes** | Chunk unloading: `x: i32`, `z: i32`, `world: String`. |
| **25** | `WorldSaveEvent` | No | World chunk data flushed to disk: `world: String`. |
| **26** | `ServerTickEvent` | No | Main server tick cycle (every 50ms): `tick_number: u64`. |
