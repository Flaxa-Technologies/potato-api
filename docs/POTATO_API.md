# PotatoMC Native Plugin API Reference (Paper-Grade Rust API)

The **PotatoMC Native Plugin API** (`potato-api`) provides high-performance, native-speed plugin capabilities for the PotatoMC/Pumpkin Minecraft server engine. Built in Rust and compiled to native dynamic shared libraries (`.dll` on Windows, `.so` on Linux, `.dylib` on macOS), PotatoMC native plugins eliminate JVM garbage collection pauses, JNI overhead, and heavy memory footprints while preserving the familiar, expressive developer ergonomics of **Bukkit**, **Spigot**, and **Paper**.

---

## 1. Paper / Spigot / Bukkit Parity Mapping

| Feature / Concept | Paper (Java) | PotatoMC Native (Rust) | Status |
|---|---|---|---|
| **Plugin Class** | `class MyPlugin extends JavaPlugin` | `struct MyPlugin; impl Plugin for MyPlugin` | Supported |
| **Plugin Metadata** | `plugin.yml` / `paper-plugin.yml` | `Plugin::metadata(&self) -> PluginMetadata` | Supported |
| **Plugin Lifecycle** | `onLoad()`, `onEnable()`, `onDisable()` | `Plugin::on_load`, `on_enable`, `on_disable` | Supported |
| **Event Handlers** | `@EventHandler(priority = HIGH)` | `context.register_event(\|event: &mut E\| { ... })` | Supported |
| **Event Priority** | `EventPriority::{LOWEST..MONITOR}` | `EventPriority::{Lowest, Low, Normal, High, Highest, Monitor}` | Supported |
| **Cancellable Events** | `Cancellable#setCancelled(boolean)` | `Cancellable::set_cancelled(&mut self, bool)` | Supported |
| **Command System** | Mojang Brigadier (`LiteralArgumentBuilder`) | `Command::tree("name").subcommand(...).executes(...)` | Supported |
| **Rich Chat Text** | Adventure `Component` & MiniMessage | `potato_api::text::Component` & `Component::from_mini_message` | Supported |
| **Tab List Header/Footer**| `Player#setPlayerListHeaderFooter(h, f)`| `Player#set_player_list_header_footer(header, footer)` | Supported |
| **Action Bar & Titles** | `Player#sendActionBar`, `Player#showTitle` | `Player#send_action_bar_component`, `send_title_components` | Supported |
| **BossBars** | Adventure `BossBar` (`bossBar(...)`) | `potato_api::bossbar::BossBar` & `player.show_bossbar(bar)` | Supported |
| **Task Scheduler** | `BukkitScheduler` (sync, async, repeating) | `PluginContext#schedule_task`, `schedule_async`, `schedule_repeating` | Supported |
| **Configuration** | `FileConfiguration` (YAML dot notation) | `PluginContext#config()` (`get_string`, `get_int_or`, dot notation) | Supported |
| **Persistent Data (PDC)** | `PersistentDataContainer` (namespaced keys) | `PersistentDataContainer` (`get_string`, `set_int`, `get_bytes`) | Supported |
| **Item Stacks & Enchants** | `ItemStack` & `ItemMeta` | `ItemStack` with `enchantments: HashMap<String, u32>` & PDC | Supported |

---

## 2. Project Templates & Setup

PotatoMC provides two ready-to-use production plugin templates in the server repository under `templates/`:

1. **Windows Template**: `templates/potato-plugin-windows` (produces `.dll`)
2. **Linux Template**: `templates/potato-plugin-linux` (produces `.so`)

### 2.1 Cargo Configuration (`Cargo.toml`)

Every PotatoMC native plugin is configured with `crate-type = ["cdylib"]`:

```toml
[package]
name = "my-potato-plugin"
version = "0.1.0"
edition = "2024"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { path = "../../Pumpkin/crates/potato-api" }
# For standalone external projects, specify git repo or local relative path
```

### 2.2 Entrypoint Macro (`potato_plugin!`)

Every plugin exports its initialization symbol using the `potato_plugin!` macro:

```rust
use potato_api::plugin::{Plugin, PluginContext, PluginMetadata};
use potato_api::potato_plugin;

#[derive(Default)]
pub struct MyPlugin;

impl Plugin for MyPlugin {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("MyPlugin", "1.0.0")
            .author("Developer")
            .description("A high-performance native PotatoMC plugin")
    }

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("MyPlugin loaded!");
        Ok(())
    }

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("MyPlugin enabled!");
        Ok(())
    }

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("MyPlugin disabled!");
        Ok(())
    }
}

// Exports the C-ABI symbol POTATO_API_VERSION and potato_create_plugin()
potato_plugin!(MyPlugin);
```

### 2.3 Compiling & Deploying

#### Windows:
```cmd
cd templates/potato-plugin-windows
cargo build --release
copy target\release\my_potato_plugin.dll ..\..\plugins\
```
Or run the bundled `build.bat` / `build.ps1` script.

#### Linux:
```bash
cd templates/potato-plugin-linux
cargo build --release
cp target/release/libmy_potato_plugin_linux.so ../../plugins/
```
Or run `build.sh` / `make`.

---

## 3. Configuration API (YAML with Dot-Notation)

The Configuration API mirrors Bukkit's `FileConfiguration`. You can save default configurations embedded in your plugin binary, read typed values, and access nested keys using dot notation (e.g. `messages.welcome`).

```rust
// In on_load:
let default_config = r#"
server:
  motd: "<gold>Welcome to PotatoMC!</gold>"
  max_players: 100
features:
  pvp_enabled: true
  spawn_protection_radius: 16
"#;
context.save_default_config(default_config)?;

// In on_enable:
let config = context.config();

let motd = config.get_string_or("server.motd", "Default MOTD");
let max_players = config.get_int_or("server.max_players", 50);
let pvp = config.get_bool_or("features.pvp_enabled", true);
let radius = config.get_float_or("features.spawn_protection_radius", 16.0);
```

---

## 4. Adventure Text & MiniMessage

PotatoMC natively supports the **Adventure component standard** and **MiniMessage formatting tags**:

```rust
use potato_api::text::{Component, NamedTextColor, TextDecoration};

// 1. Fluent Component builder
let greeting = Component::text("Hello, ")
    .color(NamedTextColor::Green)
    .append(
        Component::text("Player")
            .color(NamedTextColor::Gold)
            .bold()
    );

// 2. MiniMessage tag syntax
let styled = Component::from_mini_message(
    "<gradient:#ffaa00:#ff5555><bold>Server Alert:</bold></gradient> Maintenance in <red>5 minutes</red>!"
);

// 3. Dispatch to player
player.send_component(&styled);
player.send_action_bar_component(&Component::text("§eSaving world..."));

// 4. Titles
player.send_title_components(
    &Component::from_mini_message("<gold><bold>LEVEL UP!</bold></gold>"),
    &Component::text("You reached level 10"),
    10,  // fade_in (ticks)
    70,  // stay (ticks)
    20,  // fade_out (ticks)
);

// 5. Player Tab List Header & Footer (Spigot/Paper)
player.set_player_list_header_footer(
    "§6§lPotatoMC Server",
    "§7Ping: 12ms §8| §7TPS: 20.0"
);
```

---

## 5. Event System & Cancellable

The event system uses a publisher/observer pattern. Handlers can inspect event state and cancel cancellable actions.

### 5.1 Event Priority Order
1. `EventPriority::Lowest`
2. `EventPriority::Low`
3. `EventPriority::Normal` (Default)
4. `EventPriority::High`
5. `EventPriority::Highest`
6. `EventPriority::Monitor` (Read-only observation)

### 5.2 Event Registration Examples

```rust
use potato_api::event::{BlockBreakEvent, Cancellable, PlayerJoinEvent, PlayerInteractEvent};

// Player Join Event
context.register_event(|event: &mut PlayerJoinEvent| {
    let player_name = event.player.name();
    let welcome = format!("<yellow>Welcome, <gold>{}</gold> to the server!</yellow>", player_name);
    event.player.send_component(&Component::from_mini_message(&welcome));
});

// Block Break Event (with cancellation)
context.register_event(|event: &mut BlockBreakEvent| {
    if event.block.block_type == "minecraft:bedrock" {
        event.set_cancelled(true);
        if let Some(ref player) = event.player {
            player.send_message("§cYou cannot break bedrock!");
        }
    }
});

// Player Interaction Event
context.register_event(|event: &mut PlayerInteractEvent| {
    if let Some(ref block) = event.clicked_block {
        if block.block_type == "minecraft:diamond_block" {
            event.player.send_message("§bYou tapped a diamond block!");
        }
    }
});
```

### 5.3 Complete Event Catalog

| ID | Event Struct | Cancellable | Description |
|---|---|:---:|---|
| 1 | `ServerStartedEvent` | No | Server has completed startup and is accepting players |
| 2 | `ServerStoppingEvent` | No | Server is preparing to shut down |
| 3 | `PlayerJoinEvent` | No | Player connected and entered world |
| 4 | `PlayerQuitEvent` | No | Player disconnected from server |
| 5 | `PlayerChatEvent` | Yes | Player sent a chat message |
| 6 | `PlayerMoveEvent` | Yes | Player changed coordinates/rotation |
| 7 | `PlayerInteractEvent` | Yes | Player left/right clicked block or air |
| 8 | `PlayerTeleportEvent` | Yes | Player teleportation initiated |
| 9 | `PlayerToggleFlightEvent`| Yes | Player toggled creative/spectator flight |
| 10 | `PlayerToggleSneakEvent` | Yes | Player started or stopped sneaking |
| 11 | `PlayerToggleSprintEvent`| Yes | Player started or stopped sprinting |
| 12 | `PlayerRespawnEvent` | No | Player died and clicked respawn button |
| 13 | `BlockBreakEvent` | Yes | Player mined and broke a block |
| 14 | `BlockPlaceEvent` | Yes | Player placed a block into the world |
| 15 | `EntityDamageEvent` | Yes | Entity took damage from a source |
| 16 | `EntityDeathEvent` | No | Entity health reached zero |
| 17 | `EntitySpawnEvent` | Yes | Entity is about to spawn in world |
| 18 | `ItemDropEvent` | Yes | Player dropped an item stack |
| 19 | `ItemPickupEvent` | Yes | Player picked up a dropped item |
| 20 | `InventoryOpenEvent` | Yes | Player opened an inventory container |
| 21 | `InventoryCloseEvent` | No | Player closed an inventory container |
| 22 | `InventoryClickEvent` | Yes | Player clicked a slot inside an inventory |
| 23 | `ChunkLoadEvent` | No | Chunk loaded into active memory |
| 24 | `ChunkUnloadEvent` | Yes | Chunk about to be unloaded from memory |
| 25 | `WorldSaveEvent` | No | World data flushed to disk |
| 26 | `ServerTickEvent` | No | Main server tick executed (every 50ms) |

---

## 6. Brigadier Command API

Commands are structured as tree builders with arguments and execute callbacks:

```rust
use potato_api::command::{Argument, Command, CommandContext, CommandResult, CommandSender};
use potato_api::text::{Component, NamedTextColor};

let cmd = Command::tree("potato")
    .description("PotatoMC core command")
    .alias("pot")
    .subcommand(
        Command::tree("broadcast")
            .description("Broadcast an announcement")
            .argument(Argument::string("message"))
            .executes(|ctx: &CommandContext| -> CommandResult {
                let msg = ctx.get_string("message").unwrap_or("Hello!");
                let component = Component::from_mini_message(&format!("<yellow>[Server]</yellow> <white>{}</white>", msg));
                
                ctx.broadcast_component(&component);
                CommandResult::Ok
            })
    )
    .subcommand(
        Command::tree("heal")
            .description("Restore health to max")
            .executes(|ctx: &CommandContext| -> CommandResult {
                if let CommandSender::Player(player) = ctx.sender() {
                    player.set_health(20.0);
                    player.send_message("§aYou have been healed!");
                }
                CommandResult::Ok
            })
    );

context.register_command(cmd);
```

---

## 7. BossBar API (Paper Adventure Parity)

PotatoMC supports interactive, per-player BossBars:

```rust
use potato_api::bossbar::{BossBar, BossBarColor, BossBarStyle};
use potato_api::text::Component;

let bossbar = BossBar::new(
    Component::from_mini_message("<red><bold>Raid Boss</bold></red>"),
    1.0, // 100% progress
    BossBarColor::Red,
    BossBarStyle::Progress,
);

// Show to player
player.show_bossbar(&bossbar);

// Update progress
bossbar.set_progress(0.75);

// Hide when done
player.hide_bossbar(&bossbar.id());
```

---

## 8. Scheduler API (Concurrency & Background Tasks)

All world-modifying logic runs safely synchronized with server ticks, while long-running I/O (database, webhooks) runs asynchronously:

```rust
use std::time::Duration;

// 1. Run once after delay (20 ticks = 1 second)
context.schedule_task(Duration::from_millis(1000), || {
    // Executes on server thread
});

// 2. Repeating task (every 5 seconds)
let task_id = context.schedule_repeating(Duration::from_secs(5), || {
    // Tick check / autosave / stats
});

// 3. Asynchronous off-thread background worker
context.schedule_async(|| {
    // Perform database query, disk I/O, or HTTP request off the main thread
    let stats = query_external_database();
    println!("Database responded: {}", stats);
});
```

---

## 9. Persistent Data Container (PDC) & ItemStacks

Bukkit's PDC allows plugins to attach arbitrary typed data directly to `ItemStack` and entities without raw NBT hacking.

```rust
use potato_api::types::{ItemStack, PersistentDataContainer};

let mut sword = ItemStack::new("minecraft:diamond_sword", 1);

// Set display name and lore
sword.set_display_name("§6Excalibur");
sword.add_lore("§7Forged in ancient fires");

// Add enchantments
sword.add_enchantment("minecraft:sharpness", 5);
sword.add_enchantment("minecraft:unbreaking", 3);

// Attach Persistent Data
let mut pdc = PersistentDataContainer::new();
pdc.set_string("rpg:rarity", "LEGENDARY");
pdc.set_int("rpg:level_requirement", 50);
pdc.set_bytes("rpg:signature", vec![0xDE, 0xAD, 0xBE, 0xEF]);
sword.set_pdc(pdc);

// Read back data
if let Some(rarity) = sword.pdc.get_string("rpg:rarity") {
    println!("Item rarity: {}", rarity);
}
```

---

## 10. Best Practices

1. **Keep Event Handlers Non-Blocking**: Heavy I/O (database calls, web requests) should be executed via `context.schedule_async(...)`.
2. **Handle Cancellation Gracefully**: Check `event.is_cancelled()` in later priority listeners when modifying game state.
3. **Use MiniMessage for Coloration**: MiniMessage tags (`<green>`, `<gradient>`, `<bold>`) are safer, cleaner, and more readable than raw legacy section codes (`§`).
4. **Deploy Standalone Dynlibs**: Always copy the compiled `.dll` or `.so` directly into your server's `plugins/` folder. PotatoMC will discover, load, and activate them on startup!
