@echo off
setlocal
echo ========================================================
echo  PotatoMC Windows Plugin Build Script (.dll)
echo ========================================================
echo.

where cargo >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 'cargo' not found in PATH!
    echo Please install Rust via https://rustup.rs/
    exit /b 1
)

echo [1/2] Compiling plugin in release mode...
cargo build --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed! Check compiler errors above.
    exit /b %ERRORLEVEL%
)

echo.
echo [2/2] Build successful!
set OUTPUT=target\release\my_potato_plugin.dll

if exist "%OUTPUT%" (
    echo Produced: %OUTPUT%
    if exist "..\..\plugins\" (
        copy /Y "%OUTPUT%" "..\..\plugins\"
        echo Deployed to ..\..\plugins\my_potato_plugin.dll
    )
)

echo ========================================================
echo  Build complete! Drop the .dll into your server plugins/
echo ========================================================
