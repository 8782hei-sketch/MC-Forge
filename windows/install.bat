@echo off
title Minecraft Forge Server - Auto Installer
setlocal

REM =============================================================
REM  Minecraft Forge Server - Auto Installer (Windows launcher)
REM  File ini cuma "pembungkus" yang menjalankan install.ps1
REM  (logika berat pakai PowerShell karena jauh lebih mudah buat
REM   baca JSON/XML dan download file ketimbang pure batch).
REM =============================================================

where powershell >nul 2>nul
if errorlevel 1 (
    echo [ERROR] PowerShell tidak ditemukan di sistem ini.
    echo Script ini butuh PowerShell ^(sudah bawaan Windows 10/11^).
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1"

echo.
pause
