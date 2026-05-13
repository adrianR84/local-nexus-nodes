#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Sync shell files to WSL Ubuntu directory
    
.DESCRIPTION
    This script copies all .sh files from the nexus-nodes directory to WSL Ubuntu
    and sets executable permissions.
#>

# Source and destination paths
$sourcePath = "c:\_Adi\_Work\Apps\_scripts\nexus-nodes\*.sh"
$destinationPath = "\\wsl.localhost\Ubuntu-18.04\home\adi\nexus-nodes\"

Write-Host "Syncing shell files to WSL Ubuntu..." -ForegroundColor Cyan
Write-Host "Source: $sourcePath" -ForegroundColor Gray
Write-Host "Destination: $destinationPath" -ForegroundColor Gray
Write-Host ""

try {
    # Check if WSL is running
    $wslStatus = wsl --list --running
    if ($wslStatus -notmatch "Ubuntu-18.04") {
        Write-Host "Starting Ubuntu-18.04 WSL distribution..." -ForegroundColor Yellow
        wsl -d Ubuntu-18.04 -- echo "WSL Ubuntu started"
    }
    
    # Create destination directory if it doesn't exist
    Write-Host "Creating destination directory if needed..." -ForegroundColor Cyan
    wsl -d Ubuntu-18.04 -- mkdir -p /home/adi/nexus-nodes
    
    # Copy shell files
    Write-Host "Copying shell files..." -ForegroundColor Green
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force -Recurse
    
    # Set executable permissions
    Write-Host "Setting executable permissions..." -ForegroundColor Green
    wsl -d Ubuntu-18.04 -- chmod +x /home/adi/nexus-nodes/*.sh
    
    # List files in destination
    Write-Host "Files in WSL Ubuntu directory:" -ForegroundColor Cyan
    wsl -d Ubuntu-18.04 -- ls -la /home/adi/nexus-nodes/
    
    Write-Host "Sync completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "Error during sync: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure WSL Ubuntu-18.04 is installed and accessible." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Sync completed! This window will close automatically in 3 seconds..." -ForegroundColor Green
Start-Sleep -Seconds 3
