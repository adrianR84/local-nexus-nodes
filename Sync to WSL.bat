@echo off
title Sync Shell Files to WSL
color 0A

echo.
echo ========================================
echo    Sync Shell Files to WSL Ubuntu
echo ========================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0sync-to-wsl.ps1"

echo.
echo Window will close automatically...
timeout /t 2 /nobreak >nul
