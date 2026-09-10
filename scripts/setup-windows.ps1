# ==============================================================================
# PotatoMC Native Plugin Development Environment Setup - Windows (PowerShell)
# ==============================================================================

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " PotatoMC Native Plugin Development Environment Setup (Windows)  " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Check for Rust / Cargo
Write-Host "[1/4] Checking Rust toolchain..." -ForegroundColor Yellow
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Cargo not detected! Downloading and installing rustup..." -ForegroundColor Yellow
    $rustupUrl = "https://win.rustup.rs/x86_64"
    $installer = "$env:TEMP\rustup-init.exe"
    Invoke-WebRequest -Uri $rustupUrl -OutFile $installer
    Start-Process -FilePath $installer -ArgumentList "-y", "--default-toolchain", "stable" -Wait
    Remove-Item -Force $installer
    $env:PATH += ";$env:USERPROFILE\.cargo\bin"
    Write-Host "[✓] Rust installed successfully!" -ForegroundColor Green
} else {
    $ver = & cargo --version
    Write-Host "[✓] $ver detected!" -ForegroundColor Green
}

# 2. Verify MSVC target
Write-Host "[2/4] Checking default Rust target..." -ForegroundColor Yellow
& rustup default stable | Out-Null
& rustup target add x86_64-pc-windows-msvc | Out-Null
Write-Host "[✓] Target 'x86_64-pc-windows-msvc' is installed and ready." -ForegroundColor Green

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
