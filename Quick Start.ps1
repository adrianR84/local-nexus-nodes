#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Quick Start Nexus Network Manager - Sync and open WSL terminal
    
.DESCRIPTION
    This script syncs files to WSL and opens terminal ready to launch Nexus Network Manager
#>

Write-Host "Nexus Network Quick Start" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Syncing files to WSL..." -ForegroundColor Green
& ".\sync-to-wsl.ps1"

Write-Host ""
Write-Host "Opening WSL terminal with command ready..." -ForegroundColor Green
wsl -d Ubuntu-18.04 -- bash -c "cd /home/adi/nexus-nodes && echo './launch_nexus_nodes.sh' && exec bash"

Write-Host ""
Write-Host "Quick Start completed!" -ForegroundColor Green
Write-Host "Press any key to close..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
