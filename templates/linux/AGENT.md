# AGENT.md — PotatoMC Native Plugin Development Guide for AI Agents

This file guides AI coding agents (Antigravity, Claude, Copilot, Cursor, etc.) working on this PotatoMC native plugin codebase.

---

## 1. Project Overview & Architecture
- **Engine**: PotatoMC (high-performance Minecraft server in Rust)
- **Plugin Type**: Native dynamic shared library (`crate-type = ["cdylib"]`)
  - Linux: produces `.so` (`target/release/lib<crate_name>.so`)
  - Windows: produces `.dll` (`target\release\<crate_name>.dll`)
  - macOS: produces `.dylib` (`target/release/lib<crate_name>.dylib`)
- **Execution Model**: Runs directly in-process with the PotatoMC engine at native speed. Zero JVM overhead, zero JNI boundary crossings, zero GC hitches.

---

## 2. Where to Get Official API Documentation
Always consult the official PotatoMC API documentation when implementing features:

- **Repository**: [https://github.com/Flaxa-Technologies/potato-api](https://github.com/Flaxa-Technologies/potato-api)
- **Documentation Hub**: [https://github.com/Flaxa-Technologies/potato-api/tree/main/docs](https://github.com/Flaxa-Technologies/potato-api/tree/main/docs)

### Direct Topic Guides:
- **[Lifecycle & Entrypoint](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/LIFECYCLE.md)**: `Plugin` trait (`on_load`, `on_enable`, `on_disable`), metadata, `potato_plugin!(Struct)`
- **[Event System & Catalog](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md)**: All 26 events (Join, Break, Place, Damage, Chat, Interact, etc.), `Cancellable`, `EventPriority`
- **[Brigadier Command API](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md)**: Tree builders (`Command::tree`), arguments (`word`, `string`, `int`, `float`, `bool`, `player`), executors, subcommands
- **[Adventure & MiniMessage](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md)**: `Component::from_mini_message`, gradients, colors, action bar, titles, tab list header/footer
- **[PDC & ItemStacks](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md)**: Persistent Data Container (`strings`, `ints`, `longs`, `bytes`), `ItemStack`, custom enchantments, lore
- **[Scheduler & Concurrency](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md)**: Main-thread delayed (`run_task_later`), repeating timers (`run_task_repeating`), off-thread workers
- **[YAML Configuration](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/CONFIGURATION.md)**: Dot-notation config queries (`get_string_or`, `get_int_or`, `get_bool_or`), default config generation
- **[BossBar API](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/BOSSBAR.md)**: Adventure BossBars, colors, division overlay styles, dynamic progress
- **[Paper to PotatoMC Guide](https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PAPER_MIGRATION.md)**: Java Bukkit/Spigot/Paper translations

---

## 3. Build & Verification Commands
- **Check code syntax/types without building binaries**:
  ```bash
  cargo check
  ```
- **Compile optimized release binary**:
  ```bash
  cargo build --release
  ```
- **Output binaries**:
  - Linux: `target/release/lib*.so`
  - Windows: `target/release/*.dll`
  - macOS: `target/release/lib*.dylib`

---

## 4. Agent Coding Guidelines
1. **Always export entrypoint**: Make sure `potato_plugin!(YourPluginStruct);` is called at the end of `src/lib.rs`.
2. **Never block the server tick thread**: Heavy tasks (database I/O, web requests, disk writes) must run in `std::thread::spawn` or background tasks.
3. **Cancellation**: If an event can be cancelled, check `event.set_cancelled(true)`.
4. **Verification**: Always run `cargo check` after making edits to confirm 0 compilation errors.

---

## 5. Support & Community
- **Website**: [https://potatomc.flaxa.in/](https://potatomc.flaxa.in/)
- **Discord**: [Flaxa Studios Discord](https://discord.com/invite/UUaNzfZyc6) (#api-suggestions, #plugin-development)
- **Issues**: [GitHub Issues](https://github.com/Flaxa-Technologies/potato-api/issues)
