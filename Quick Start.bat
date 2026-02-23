@echo off
echo Nexus Network Quick Start
echo ========================
echo.

echo Syncing files to WSL...
powershell -ExecutionPolicy Bypass -File "sync-to-wsl.ps1"

echo.
echo Opening WSL terminal with command ready...
wsl -d Ubuntu-18.04 -- bash -c "cd /home/adi/nexus-nodes && echo './launch_nexus_nodes.sh' && exec bash"

echo.
echo Quick Start completed!
