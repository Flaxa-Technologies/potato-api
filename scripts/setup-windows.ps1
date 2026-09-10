# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - Windows (PowerShell)
# ==============================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " PotatoMC Native Plugin Development Environment Setup (Windows)  " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Check for Rust / Cargo
Write-Host "[1/4] Checking Rust toolchain..." -ForegroundColor Yellow

$cargoFound = $false
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    $cargoFound = $true
} else {
    $cargoExe = "$env:USERPROFILE\.cargo\bin\cargo.exe"
    if (Test-Path $cargoExe) {
        $env:PATH = "$env:USERPROFILE\.cargo\bin;" + $env:PATH
        $cargoFound = $true
    }
}

if ($cargoFound) {
    $ver = & cargo --version
    Write-Host "[✓] Rust toolchain detected: $ver" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[!] Cargo / Rust toolchain was not found on your system." -ForegroundColor Yellow

    # Ask user for automatic installation
    $choice = Read-Host "Would you like to automatically download and install Rust and Cargo now? [Y/n]"
    if ($choice -match '^[Nn]') {
        Write-Host ""
        Write-Host "[i] Auto-installation cancelled." -ForegroundColor Cyan
        Write-Host "Please download and install Rust manually from: https://win.rustup.rs/x86_64" -ForegroundColor White
        exit 0
    }

    Write-Host "[*] Downloading and installing rustup..." -ForegroundColor Yellow
    $rustupUrl = "https://win.rustup.rs/x86_64"
    $installer = "$env:TEMP\rustup-init.exe"
    Invoke-WebRequest -Uri $rustupUrl -OutFile $installer
    Start-Process -FilePath $installer -ArgumentList "-y", "--default-toolchain", "stable" -Wait
    Remove-Item -Force $installer -ErrorAction SilentlyContinue

    $env:PATH = "$env:USERPROFILE\.cargo\bin;" + $env:PATH

    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        $ver = & cargo --version
        Write-Host "[✓] Rust installed successfully: $ver" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Installation completed, but 'cargo' is not yet in PATH." -ForegroundColor Red
        Write-Host "Please restart your terminal or add `$env:USERPROFILE\.cargo\bin to PATH." -ForegroundColor Yellow
        exit 1
    }
}

# 2. Verify MSVC target
Write-Host "[2/4] Checking default Rust target..." -ForegroundColor Yellow
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    & rustup default stable 2>$null | Out-Null
    & rustup target add x86_64-pc-windows-msvc 2>$null | Out-Null
    Write-Host "[✓] Target 'x86_64-pc-windows-msvc' is installed and ready." -ForegroundColor Green
}

# 3. Check C++ Build Tools
Write-Host "[3/4] Checking for Microsoft C++ Build Tools (MSVC Linker)..." -ForegroundColor Yellow
$linkCheck = Get-Command link -ErrorAction SilentlyContinue
if ($linkCheck) {
    Write-Host "[✓] MSVC Linker located at: $($linkCheck.Source)" -ForegroundColor Green
} else {
    Write-Host "[i] Note: If compilation fails during linking, ensure 'Desktop development with C++' is installed in Visual Studio Installer." -ForegroundColor Cyan
}

# 4. Interactive Plugin Scaffolding
Write-Host "[4/4] Environment ready!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  PotatoMC Windows Native Plugin Environment is Ready!           " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$wantScaffold = Read-Host "Would you like to set up a new plugin template here now? [Y/n]"
if ($wantScaffold -notmatch '^[Nn]') {
    $pName = Read-Host "Enter Plugin Name [default: MyPotatoPlugin]"
    if ([string]::IsNullOrWhiteSpace($pName)) { $pName = "MyPotatoPlugin" }

    $pAuthor = Read-Host "Enter Author Name [default: Developer]"
    if ([string]::IsNullOrWhiteSpace($pAuthor)) { $pAuthor = "Developer" }

    $dirChoice = Read-Host "Create in current directory '.' or new subfolder './$pName'? [1=Current dir, 2=Subfolder] (Default: 1)"
    $targetDir = "."
    if ($dirChoice -eq "2") {
        $targetDir = ".\$pName"
    }

    $crateName = $pName.ToLower().Replace(' ', '-').Replace('_', '-')
    $structName = $pName.Replace('-', '_').Replace(' ', '_')
    $cmdName = if ($crateName.Length -gt 8) { $crateName.Substring(0, 8) } else { $crateName }

    New-Item -ItemType Directory -Path "$targetDir\src" -Force | Out-Null

    # Cargo.toml
    $cargoContent = @"
[package]
name = "$crateName"
version = "0.1.0"
edition = "2024"
authors = ["$pAuthor"]
description = "Native Windows PotatoMC Plugin (.dll)"

[lib]
crate-type = ["cdylib"]

[dependencies]
potato-api = { git = "https://github.com/Flaxa-Technologies/potato-api" }
"@
    Set-Content -Path "$targetDir\Cargo.toml" -Value $cargoContent -Encoding UTF8

    # src/lib.rs
    $srcContent = @"
use std::time::Duration;
use potato_api::bossbar::{BossBar, BossBarColor, BossBarStyle};
use potato_api::command::{Argument, Command, CommandContext, CommandResult, CommandSender};
use potato_api::event::{
    BlockBreakEvent, Cancellable, PlayerChatEvent, PlayerInteractEvent, PlayerJoinEvent,
};
use potato_api::plugin::{Plugin, PluginContext, PluginMetadata};
use potato_api::potato_plugin;
use potato_api::text::{Component, NamedTextColor};
use potato_api::types::{ItemStack, PersistentDataContainer};

#[derive(Default)]
pub struct $structName;

impl Plugin for $structName {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata::new("$pName", "1.0.0")
            .author("$pAuthor")
            .description("Official Paper-grade Native Windows PotatoMC Plugin (.dll)")
    }

    fn on_load(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$pName loaded on Windows host!");
        let default_cfg = r#"# $pName Configuration
server:
  welcome_message: "<gradient:#ffaa00:#ff5555><bold>Welcome, {player}!</bold></gradient> Running on PotatoMC!"
  tab_header: "<gold><bold>PotatoMC Windows Server</bold></gold>"
  tab_footer: "<gray>Paper-grade Native Plugin (.dll)</gray>"
features:
  protect_bedrock: true
"#;
        let _ = context.save_default_config(default_cfg);
        Ok(())
    }

    fn on_enable(&self, context: &PluginContext) -> Result<(), String> {
        let logger = context.logger();
        logger.info("$pName enabling at native speed...");

        let config = context.config();
        let welcome_template = config.get_string_or(
            "server.welcome_message",
            "Welcome, {player}! Running on PotatoMC!",
        );
        let tab_header = config.get_string_or("server.tab_header", "<gold>PotatoMC</gold>");
        let tab_footer = config.get_string_or("server.tab_footer", "<gray>Native Windows .dll</gray>");
        let protect_bedrock = config.get_bool_or("features.protect_bedrock", true);

        // 1. PlayerJoinEvent
        let join_template = welcome_template.clone();
        let header_str = tab_header.clone();
        let footer_str = tab_footer.clone();
        context.register_event(move |event: &mut PlayerJoinEvent| {
            let player = &event.player;
            let player_name = player.name();

            let formatted = join_template.replace("{player}", &player_name);
            let component = Component::from_mini_message(&formatted);
            player.send_component(&component);

            let h = Component::from_mini_message(&header_str);
            let f = Component::from_mini_message(&footer_str);
            player.set_player_list_header_footer(&h.to_legacy_string(), &f.to_legacy_string());
        });

        // 2. BlockBreakEvent: cancel bedrock break
        if protect_bedrock {
            context.register_event(move |event: &mut BlockBreakEvent| {
                if event.block.block_type == "minecraft:bedrock" {
                    event.set_cancelled(true);
                    if let Some(ref player) = event.player {
                        player.send_message("§cYou cannot break bedrock!");
                    }
                }
            });
        }

        // 3. PlayerInteractEvent
        context.register_event(move |event: &mut PlayerInteractEvent| {
            if let Some(ref block) = event.clicked_block {
                if block.block_type == "minecraft:diamond_block" {
                    event.player.send_message("§b✨ You tapped a Diamond Block!");
                }
            }
        });

        // 4. Brigadier Commands
        let cmd = Command::tree("$cmdName")
            .description("Command provided by $pName")
            .subcommand(
                Command::tree("greet")
                    .argument(Argument::word("target"))
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let target = ctx.get_string("target").unwrap_or("Friend");
                        let comp = Component::text("Hello, ")
                            .color(NamedTextColor::Yellow)
                            .append(Component::text(target).color(NamedTextColor::Green).bold())
                            .append(Component::text(" from Windows native plugin!"));

                        match ctx.sender() {
                            CommandSender::Player(p) => p.send_component(&comp),
                            CommandSender::Console(c) => c.send_message(&comp.to_plain_text()),
                        }
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("item")
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let mut item = ItemStack::new("minecraft:diamond_sword", 1);
                        item.set_custom_name("§6§lExcalibur of the North");
                        item.add_lore("§7Crafted in native Rust code");
                        item.add_enchantment("minecraft:sharpness", 5);

                        let mut pdc = PersistentDataContainer::new();
                        pdc.set_string("rpg:rarity", "LEGENDARY");
                        item.set_pdc(pdc);

                        ctx.sender().send_message(&format!(
                            "§aCreated item '{}' with PDC rarity: {:?}",
                            item.custom_name.as_deref().unwrap_or(""),
                            item.pdc().get_string("rpg:rarity")
                        ));
                        Ok(())
                    }),
            )
            .subcommand(
                Command::tree("bossbar")
                    .executes(|ctx: &CommandContext| -> CommandResult {
                        let bar = BossBar::new(
                            "§6§lWindows Core Titan",
                            BossBarColor::Yellow,
                            BossBarStyle::Notched10,
                        ).with_progress(0.85);

                        ctx.sender().send_message(&format!("§aCreated BossBar '{}'", bar.title));
                        Ok(())
                    }),
            )
            .executes(|ctx: &CommandContext| -> CommandResult {
                ctx.sender().send_message("§eUsage: /$cmdName <greet <target> | item | bossbar>");
                Ok(())
            });

        context.register_command(cmd);

        // 5. Scheduler
        let setup_logger = context.logger().clone();
        context.scheduler().run_task_later(Duration::from_secs(5), move || {
            setup_logger.info("Delayed 5-second task executed on Windows main thread.");
        });

        let timer_logger = context.logger().clone();
        let _ = context.scheduler().run_task_repeating(
            Duration::from_secs(60),
            Duration::from_secs(60),
            move || {
                timer_logger.debug("Windows plugin periodic heartbeat tick.");
            },
        );

        let async_logger = context.logger().clone();
        std::thread::spawn(move || {
            async_logger.info("Async background worker running off main thread!");
        });

        logger.info("$pName enabled successfully on Windows (.dll)!");
        Ok(())
    }

    fn on_disable(&self, context: &PluginContext) -> Result<(), String> {
        context.logger().info("$pName disabled.");
        Ok(())
    }
}

potato_plugin!($structName);
"@
    Set-Content -Path "$targetDir\src\lib.rs" -Value $srcContent -Encoding UTF8

    # build.bat
    $batContent = @"
@echo off
cargo build --release
echo Built: target\release\$crateName.dll
"@
    Set-Content -Path "$targetDir\build.bat" -Value $batContent -Encoding UTF8

    # build.ps1
    $ps1Content = @"
cargo build --release
Write-Host "Built: target\release\$crateName.dll" -ForegroundColor Green
"@
    Set-Content -Path "$targetDir\build.ps1" -Value $ps1Content -Encoding UTF8

    # .gitignore
    $gitIgnore = "/target/`nCargo.lock`n*.dll`n*.so`n*.dylib`n*.pdb"
    Set-Content -Path "$targetDir\.gitignore" -Value $gitIgnore -Encoding UTF8

    # README.md
    $readmeContent = @"
# $pName

Official Paper-grade Native Windows Plugin for PotatoMC (.dll).

## Build
```cmd
cargo build --release
```
The output will be placed in: `target\release\$crateName.dll`
"@
    Set-Content -Path "$targetDir\README.md" -Value $readmeContent -Encoding UTF8

    # AGENT.md
    $agentContent = @"
# AGENT.md — PotatoMC Native Plugin Development Guide for AI Agents

This file provides critical context and rules for AI coding agents working on this PotatoMC native plugin codebase.

## 1. Project Overview
- **Engine**: PotatoMC (high-performance Rust Minecraft server)
- **Plugin Type**: Native dynamic shared library (`crate-type = ["cdylib"]`)
- **Output Binary**: `target\release\$crateName.dll`
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
1. Always export entrypoint: `potato_plugin!($structName);` at the end of `src\lib.rs`.
2. Never block the server tick loop with heavy I/O; use `std::thread::spawn` for database or HTTP calls.
3. Event cancellation: Call `event.set_cancelled(true)` on `Cancellable` events.
4. Verify code compiles cleanly with `cargo check` before finalizing edits.
"@
    Set-Content -Path "$targetDir\AGENT.md" -Value $agentContent -Encoding UTF8

    # CLAUDE.md
    $claudeContent = @"
# CLAUDE.md — Instructions for Claude on PotatoMC Native Plugins

## Project Summary
- Native PotatoMC plugin in Rust (Edition 2024)
- Target: `crate-type = ["cdylib"]` -> `target\release\$crateName.dll`
- Paper-grade API (MiniMessage, Adventure text, Brigadier trees, PDC, 26 events)

## Commands
- `cargo check` — Check syntax and types.
- `cargo build --release` — Build release .dll library.

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

    $fullPath = (Resolve-Path $targetDir).Path
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host "  [✓] Plugin '$pName' successfully initialized!" -ForegroundColor Green
    Write-Host "  Location: $fullPath" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "To compile your native Windows plugin (.dll) right now:" -ForegroundColor Cyan
    if ($targetDir -ne ".") {
        Write-Host "  cd $targetDir" -ForegroundColor White
    }
    Write-Host "  cargo build --release" -ForegroundColor White
    Write-Host ""
    Write-Host "Your compiled DLL will be located at:" -ForegroundColor Yellow
    Write-Host "  target\release\$crateName.dll" -ForegroundColor White
    Write-Host "==================================================================" -ForegroundColor DarkGray
} else {
    Write-Host "Environment configured! Run 'powershell .\scripts\create-plugin.ps1' whenever you want to scaffold a plugin." -ForegroundColor Green
}

