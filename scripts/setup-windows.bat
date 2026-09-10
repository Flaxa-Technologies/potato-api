@echo off
setlocal
echo ==================================================================
echo  PotatoMC Native Plugin Development Setup (Windows CMD)
echo ==================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Setup script failed.
    exit /b %ERRORLEVEL%
)

echo Setup complete!
pause
