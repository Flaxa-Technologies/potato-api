# ========================================================
# PotatoMC Windows Plugin PowerShell Build Script (.dll)
# ========================================================

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " PotatoMC Windows Plugin PowerShell Build Script (.dll) " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] 'cargo' not found in PATH! Install Rust via https://rustup.rs/" -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Compiling plugin in release mode..." -ForegroundColor Yellow
cargo build --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Cargo build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

$dllPath = "target\release\my_potato_plugin.dll"
if (Test-Path $dllPath) {
    $info = Get-Item $dllPath
    Write-Host "[2/2] Success! Produced: $dllPath ($($info.Length) bytes)" -ForegroundColor Green
    if (Test-Path "..\..\plugins") {
        Copy-Item $dllPath -Destination "..\..\plugins\" -Force
        Write-Host "Deployed to ..\..\plugins\my_potato_plugin.dll" -ForegroundColor Green
    }
}
Write-Host "Build complete! Place the .dll into your server plugins/ folder." -ForegroundColor Cyan
