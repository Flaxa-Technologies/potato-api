param (
    [Parameter(Mandatory=$false)]
    [string]$Name = "MyPotatoPlugin",
    [string]$Author = "Developer",
    [string]$Platform = "windows",
    [string]$OutPath = "."
)

$targetDir = Join-Path $OutPath $Name
Write-Host "Creating PotatoMC plugin project: $Name at $targetDir" -ForegroundColor Cyan

if (Test-Path $targetDir) {
    Write-Host "[ERROR] Directory $targetDir already exists!" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path "$targetDir\src" -Force | Out-Null

# Create Cargo.toml
$cargoToml = @"
[package]
name = "$($Name.ToLower().Replace(' ', '-'))"
version = "0.1.0"
edition = "2024"
authors = ["$Author"]
description = "Native plugin for PotatoMC"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { git = "https://github.com/Flaxa-Technologies/potato-api" }
"@

Set-Content -Path "$targetDir\Cargo.toml" -Value $cargoToml -Encoding UTF8

# Create src/lib.rs
$libRs = @"
use potato_api::plugin::{Plugin, PluginContext, PluginMetadata};
use potato_api::event::{PlayerJoinEvent, BlockBreakEvent, Cancellable};
use potato_api::command::{Command, CommandContext, CommandResult, CommandSender, Argument};
use potato_api::text::Component;
use potato_api::potato_plugin;

#[derive(Default)]
pub struct $($Name.Replace('-', '_'));

impl Plugin for $($Name.Replace('-', '_')) {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("$Name", "1.0.0")
            .author("$Author")
            .description("A high-performance PotatoMC native plugin")
    }

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$Name loaded!");
        let _ = context.save_default_config("message: '<gold>Hello from $Name!</gold>'\n");
        Ok(())
    }

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$Name enabled!");

        // Event listener: Player join
        context.register_event(|event: &mut PlayerJoinEvent| {
            let msg = format!("<yellow>Welcome, <green>{}</green>!</yellow>", event.player.name());
            event.player.send_component(&Component::from_mini_message(&msg));
        });

        // Command: /mycmd
        let cmd = Command::tree("$($Name.ToLower().Substring(0, [Math]::Min(5, $Name.Length)))")
            .executes(|ctx: &CommandContext| -> CommandResult {
                ctx.sender().send_message("§a$Name is running smoothly!");
                Ok(())
            });
        context.register_command(cmd);

        Ok(())
    }

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$Name disabled.");
        Ok(())
    }
}

potato_plugin!($($Name.Replace('-', '_')));
"@

Set-Content -Path "$targetDir\src\lib.rs" -Value $libRs -Encoding UTF8

# Create .gitignore
$gitIgnore = @"
/target/
Cargo.lock
*.dll
*.so
*.dylib
*.pdb
"@
Set-Content -Path "$targetDir\.gitignore" -Value $gitIgnore -Encoding UTF8

$crateName = $Name.ToLower().Replace(' ', '-').Replace('_', '-')
$structName = $Name.Replace('-', '_')

# Create build scripts
if ($Platform -eq "windows") {
    $libFile = "$crateName.dll"
    $buildBat = @"
@echo off
cargo build --release
echo Built: target\release\$libFile
"@
    Set-Content -Path "$targetDir\build.bat" -Value $buildBat -Encoding UTF8
} else {
    $libFile = "lib$($crateName.Replace('-', '_')).so"
    $buildSh = @"
#!/usr/bin/env bash
cargo build --release
echo Built: target/release/$libFile
"@
    Set-Content -Path "$targetDir\build.sh" -Value $buildSh -Encoding UTF8
}

# Create README.md
$readmeContent = @"
# $Name

Official Paper-grade Native Plugin for PotatoMC.

## Building
```bash
cargo build --release
```
The compiled shared library will be generated at:
`target/release/$libFile`

Copy this library file into your PotatoMC server's `plugins/` folder.
"@
Set-Content -Path "$targetDir\README.md" -Value $readmeContent -Encoding UTF8

# Create AGENT.md
$agentContent = @"
# AGENT.md — PotatoMC Native Plugin Development Guide for AI Agents

This file provides critical context and rules for AI coding agents working on this PotatoMC native plugin codebase.

## 1. Project Overview
- **Engine**: PotatoMC (high-performance Rust Minecraft server)
- **Plugin Type**: Native dynamic shared library (`crate-type = ["cdylib"]`)
- **Output Binary**: `target/release/$libFile`
- **Runtime Model**: Executes in-process at native C-ABI speed. Zero JVM pauses, zero JNI overhead.

## 2. API Documentation Links
Always consult the official PotatoMC API documentation when writing code:
- **API Repository**: https://github.com/Flaxa-Technologies/potato-api
- **Documentation Hub**: https://github.com/Flaxa-Technologies/potato-api/tree/main/docs
- **Lifecycle & Entrypoint**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/LIFECYCLE.md
- **Event System (26 events)**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md
- **Brigadier Commands**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md
- **Adventure Text & MiniMessage**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md
- **PDC & ItemStacks**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md
- **Scheduler & Concurrency**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md
- **YAML Configuration**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/CONFIGURATION.md
- **BossBar API**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/BOSSBAR.md
- **Paper to PotatoMC Guide**: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PAPER_MIGRATION.md

## 3. Build & Check Commands
- Fast syntax/type check: `cargo check`
- Compile release binary: `cargo build --release`

## 4. Agent Coding Rules
1. Always export entrypoint: `potato_plugin!($structName);` at the end of `src/lib.rs`.
2. Never block the server tick loop with heavy I/O; use `std::thread::spawn` for database or HTTP calls.
3. Event cancellation: Call `event.set_cancelled(true)` on `Cancellable` events.
4. Verify code compiles cleanly with `cargo check` before finalizing edits.
"@
Set-Content -Path "$targetDir\AGENT.md" -Value $agentContent -Encoding UTF8

# Create CLAUDE.md
$claudeContent = @"
# CLAUDE.md — Instructions for Claude on PotatoMC Native Plugins

## Project Summary
- Native PotatoMC plugin in Rust (Edition 2024)
- Target: `crate-type = ["cdylib"]` -> `target/release/$libFile`
- Paper-grade API (MiniMessage, Adventure text, Brigadier trees, PDC, 26 events)

## Commands
- `cargo check` — Check syntax and types.
- `cargo build --release` — Build release library.

## API Documentation
- Full Documentation: https://github.com/Flaxa-Technologies/potato-api/tree/main/docs
- Events: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/EVENTS.md
- Commands: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/COMMANDS.md
- Text/MiniMessage: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/TEXT_AND_MINIMESSAGE.md
- PDC/Items: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/PDC_AND_ITEMS.md
- Scheduler: https://github.com/Flaxa-Technologies/potato-api/blob/main/docs/SCHEDULER.md

## Rules
1. Implement `Plugin` trait with `Default`.
2. Export C-ABI symbol with `potato_plugin!($structName)`.
3. Use Adventure `Component::from_mini_message` for rich formatting.
4. Always verify code compiles cleanly with `cargo check`.
"@
Set-Content -Path "$targetDir\CLAUDE.md" -Value $claudeContent -Encoding UTF8

Write-Host "[✓] Plugin project created successfully at: $targetDir" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  cd $targetDir" -ForegroundColor White
Write-Host "  cargo build --release" -ForegroundColor White
