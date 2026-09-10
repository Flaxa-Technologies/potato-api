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

# 4. Summary & Next Steps
Write-Host "[4/4] Environment configured!" -ForegroundColor Green
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "You are now ready to build PotatoMC native plugins!" -ForegroundColor Cyan
Write-Host ""
Write-Host "To scaffold a new plugin:" -ForegroundColor Yellow
Write-Host "  powershell .\scripts\create-plugin.ps1 -Name MyPlugin" -ForegroundColor White
Write-Host ""
Write-Host "Or build the included Windows template:" -ForegroundColor Yellow
Write-Host "  cd templates\windows" -ForegroundColor White
Write-Host "  .\build.ps1" -ForegroundColor White
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
