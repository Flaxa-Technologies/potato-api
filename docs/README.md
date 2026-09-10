# PotatoMC Native Plugin API Documentation

<p align="center">
  <img src="../assets/LOGO.png" alt="PotatoMC Logo" width="220"/>
</p>

<p align="center">
  <b>Paper-Grade Native Rust Plugin Development Kit for PotatoMC</b><br>
  Zero JVM Overhead • Sub-Millisecond Latency • Expressive Developer Ergonomics
</p>

<p align="center">
  <a href="https://potatomc.flaxa.in/">🌐 Website</a> •
  <a href="https://discord.com/invite/UUaNzfZyc6">💬 Discord (Flaxa Studios)</a> •
  <a href="https://github.com/Flaxa-Technologies/potato-api">📦 GitHub Repository</a>
</p>

---

## Documentation Index

Welcome to the complete developer documentation for PotatoMC native plugins. Explore the guides below:

1. **[Plugin Lifecycle & Architecture](LIFECYCLE.md)**
   - Plugin trait (`on_load`, `on_enable`, `on_disable`)
   - Plugin metadata declaration
   - Exporting the native dynamic library entrypoint (`potato_plugin!`)
   - Windows `.dll`, Linux `.so`, macOS `.dylib` binaries

2. **[Event System & Cancellable](EVENTS.md)**
   - Publisher / Observer pattern
   - Complete 26-event catalog (IDs 1–26)
   - `Cancellable` trait & stopping vanilla actions
   - `EventPriority` ordering (`Lowest` to `Monitor`)

3. **[Brigadier Command API](COMMANDS.md)**
   - Tree-based fluent command builders (`Command::tree`)
   - Subcommands and argument parsing (`word`, `string`, `int`, `float`, `bool`, `player`)
   - `CommandSender` (Player vs Console handling)
   - Dynamic tab suggestions

4. **[Adventure Text & MiniMessage](TEXT_AND_MINIMESSAGE.md)**
   - Adventure `Component` architecture
   - MiniMessage tag syntax (`<gradient>`, `<bold>`, hex colors)
   - Action bars & animated titles
   - Custom Tab List Header & Footer (`Player#set_player_list_header_footer`)

5. **[Persistent Data Container (PDC) & Items](PDC_AND_ITEMS.md)**
   - Attaching arbitrary typed metadata to items (`strings`, `ints`, `longs`, `bytes`)
   - `ItemStack` builder, lore, and custom names
   - Custom enchantments (`add_enchantment`, `get_enchantment_level`)

6. **[Scheduler & Concurrency](SCHEDULER.md)**
   - Main-thread tick synchronization
   - Delayed tasks (`run_task_later`)
   - Repeating interval tasks (`run_task_repeating`)
   - Asynchronous off-thread background worker threads

7. **[Configuration API](CONFIGURATION.md)**
   - YAML configuration file loader (`config.yml`)
   - Dot-notation queries (`server.motd`, `features.pvp`)
   - Type-safe getters with fallbacks (`get_string_or`, `get_int_or`, `get_bool_or`)
   - Bundling default configuration files

8. **[BossBar API](BOSSBAR.md)**
   - Creating Adventure-compatible BossBars
   - Colors and division overlay styles
   - Real-time progress updates

9. **[Paper to PotatoMC Migration Guide](PAPER_MIGRATION.md)**
   - Side-by-side Java vs. Rust code translations
   - Differences in threading and memory models
