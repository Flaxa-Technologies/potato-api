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

# Create build scripts
if ($Platform -eq "windows") {
    $buildBat = @"
@echo off
cargo build --release
echo Built: target\release\$($Name.ToLower().Replace(' ', '-')).dll
"@
    Set-Content -Path "$targetDir\build.bat" -Value $buildBat -Encoding UTF8
} else {
    $buildSh = @"
#!/usr/bin/env bash
cargo build --release
echo Built: target/release/lib$($Name.ToLower().Replace(' ', '-')).so
"@
    Set-Content -Path "$targetDir\build.sh" -Value $buildSh -Encoding UTF8
}

Write-Host "[✓] Plugin project created successfully at: $targetDir" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  cd $targetDir" -ForegroundColor White
Write-Host "  cargo build --release" -ForegroundColor White
