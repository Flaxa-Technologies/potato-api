# CLAUDE.md — Instructions for Claude Working on PotatoMC Native Plugins

This file provides context and instructions for Claude when editing or developing this PotatoMC plugin.

## Project Context
- **Framework**: PotatoMC Native Plugin API (`potato-api`)
- **Language**: Rust (Edition 2024, stable)
- **Crate Type**: `cdylib` (compiled to `.so` on Linux, `.dll` on Windows, `.dylib` on macOS)
- **API Paradigm**: Paper-grade Rust Native API (Adventure text, MiniMessage, Brigadier commands, PDC, 26 events)

## Quick Build Commands
- `cargo check` — Fast syntax and type checking.
- `cargo build --release` — Compile release dynamic library for deployment.
- Output:
  - Linux: `target/release/lib<crate>.so`
  - Windows: `target/release/<crate>.dll`
  - macOS: `target/release/lib<crate>.dylib`

## Official API Documentation
- GitHub Docs: https://github.com/Flaxa-Technologies/potato-api/tree/main/docs
- Lifecycle: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/LIFECYCLE.md
- Events: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md
- Commands: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md
- MiniMessage: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md
- PDC & Items: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md
- Scheduler: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md
- Config: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/CONFIGURATION.md
- BossBar: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/BOSSBAR.md
- Paper Migration: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PAPER_MIGRATION.md

## Coding Standards
1. Implement the `Plugin` trait and derive `Default`.
2. Always export the C-ABI symbol using `potato_plugin!(PluginStruct)`.
3. Use Adventure components (`Component::from_mini_message(...)`) for rich chat, action bar, and tab list headers.
4. Use `event.set_cancelled(true)` for cancellable events (`BlockBreakEvent`, `PlayerChatEvent`, etc.).
5. Run `cargo check` to verify changes before presenting code to the user.
