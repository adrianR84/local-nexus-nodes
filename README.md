# Nexus Network Node Manager

A comprehensive bash script for managing multiple Nexus Network nodes with a user-friendly menu interface. Features real-time monitoring, resource tracking, auto-start functionality, and modular architecture.

## Files

- `launch_nexus_nodes.sh` - Main bash script with menu-driven interface
- `resource_monitor.sh` - Modular resource monitoring functions (CPU/RAM tracking)
- `sync-to-wsl.ps1` - PowerShell script to sync shell files to WSL
- `Sync to WSL.bat` - Batch file for double-click execution
- `settings.conf` - Persistent configuration file (auto-created)
- `README.md` - This file

## Quick Start

### 1. Sync Files to WSL (Double-click)

Simply double-click `Sync to WSL.bat` to copy all shell files to your WSL Ubuntu directory and set executable permissions.

### 2. Run Nexus Network Manager

1. Open WSL Ubuntu terminal
2. Navigate to nexus directory: `cd ~/nexus`
3. Run the script: `./launch_nexus_nodes.sh`

## Menu Options

The Nexus Network Manager provides these options:

1. **Run Nexus Network Script (All Nodes)** - Launch all 12 configured nodes
2. **Run Half Nodes (Resource-Saving Mode)** - Launch only 6 nodes for reduced resource usage
3. **Check Running Processes** - Monitor CPU and memory usage
4. **Real-Time Dashboard** - Live auto-refreshing process monitor (3-second updates)
5. **Show Successful Submissions** - Live submission tracker (30-second updates)
6. **Settings** - Configure auto-cleanup and auto-start options
7. **[Dynamic] Pause/Resume Nodes** - Toggle between pause and resume states
8. **[Dynamic] Toggle All/Half Mode** - Switch between full and half node operation
9. **System Resources** - Detailed CPU/RAM monitoring with real-time updates
10. **Stop All Nexus Processes** - Emergency stop with confirmation (red option)

**Press ESC to exit** - Clean exit from the manager

### Dynamic Options

Options 7 and 8 are context-sensitive:

- **Option 7**: Shows "Pause Nodes" when nodes are running, "Resume Nodes" when paused
- **Option 8**: Shows "Switch to Half Mode" when all nodes running, "Switch to Full Mode" when half running

## Features

### 🚀 Enhanced Node Management

- Launch multiple `nexus-network start --headless --node-id` processes
- **All/Half Mode Toggle** - Switch between 12 nodes (full) and 6 nodes (half)
- **Pause/Resume Functionality** - Temporarily pause nodes without stopping them
- Automatic log file creation for each node
- Configurable node IDs in the script
- Auto-cleanup option for logs on startup

### ⏰ Auto-Start on Inactivity

- **Smart Detection** - Automatically starts/resumes nodes after inactivity timeout
- **Configurable Timeout** - Default 10 minutes, adjustable in settings
- **Exact Timing** - Precise timeout tracking based on activation time
- **State-Aware** - Handles paused, half-mode, and stopped states appropriately
- **Visual Countdown** - Shows remaining time until auto-start on main menu

### 📊 Comprehensive Resource Monitoring

- **Main Menu Summary** - Live CPU, RAM, and node count display
- **Detailed System Monitor** - Real-time resource tracking with auto-refresh
- **Script Resource Usage** - Monitor the manager script's own resource consumption
- **Node Resource Aggregation** - Combined CPU/RAM usage across all nexus nodes
- **System-Wide Resources** - Overall system resource availability
- **Smart Memory Formatting** - Automatic GB/MB/KB scaling for readability

### 📈 Real-Time Monitoring

- **Process Dashboard**: Live CPU/memory usage with color coding
- **Submission Monitor**: Track successful proofs per node with total counts
- **Resource Monitor**: Detailed system resource tracking with 5-second updates
- Auto-refreshing displays with 'q' or ESC to exit
- Color-coded resource usage indicators

### 📝 Log Management

- Individual log files per node: `logs/nexus_node_[NODE_ID].log`
- Automatic log cleanup utility
- File size tracking and management
- Configurable auto-cleanup on startup

### ⚙️ Settings Management

- **Persistent Configuration** - Settings saved to `settings.conf`
- **Auto-Clean Logs Toggle** - Enable/disable automatic log cleanup
- **Auto-Start Configuration** - Configure inactivity timeout and enable/disable
- **Settings Persistence** - Your preferences are remembered between sessions

### 🛡️ Enhanced Safety Features

- Confirmation prompts for destructive operations
- Process verification before stopping
- Graceful error handling
- Clean exit from live dashboards
- **Paused Node Detection** - Prevents starting new nodes when others are paused
- **Auto-Return Functions** - Automatic menu return with 10-second timeout or immediate Enter

## Configuration

### Node IDs

Edit the `node_ids` array in `launch_nexus_nodes.sh`:

```bash
node_ids=(
    "35835965"
    "35837105"
    "35924545"
    "35785219"
    "35900259"
    "35924549"
    "35785224"
    "35754765"
    "35837106"
    "35837107"
    "35924550"
    "35924551"
    # Add more node IDs here (up to 12 total)
)
```

### Settings File

The script automatically creates and manages `settings.conf`:

```bash
# Auto-cleanup logs on startup
AUTO_CLEAN_LOGS=true

# Auto-start nodes after inactivity
AUTO_START_INACTIVITY=true

# Inactivity timeout in minutes
INACTIVITY_TIMEOUT=10
```

## Usage Examples

### Start All Nodes

1. Run the script: `./launch_nexus_nodes.sh`
2. Select option `1` to launch all 12 nodes
3. Logs are automatically created in `logs/` directory

### Resource-Saving Mode

1. Select option `2` to launch only 6 nodes
2. Use option `8` to toggle between all/half modes
3. Monitor resource usage with option `9`

### Monitor Performance

1. Select option `3` for static process view
2. Select option `4` for real-time dashboard
3. Select option `9` for detailed system resources
4. Press 'q' or ESC to return to menu

### Track Submissions

1. Select option `5` for live submission monitor
2. Shows total successful proofs per node and overall count
3. Auto-refreshes every 30 seconds
4. Main menu also shows total submissions count

### Pause/Resume Nodes

1. Select option `7` to pause all running nodes
2. Paused nodes retain their state but stop processing
3. Select option `7` again to resume paused nodes
4. Auto-start will automatically resume paused nodes after timeout

### Configure Settings

1. Select option `6` to access settings menu
2. Toggle auto-cleanup and auto-start options
3. Adjust inactivity timeout (5-60 minutes)
4. Settings are automatically saved

### Emergency Stop

1. Select option `0` to stop all processes
2. Review running processes in the warning
3. Confirm with 'y' to proceed

## File Structure

```
nexus/
├── launch_nexus_nodes.sh    # Main script
├── resource_monitor.sh      # Resource monitoring module
├── sync-to-wsl.ps1         # WSL sync script
├── Sync to WSL.bat         # Double-click launcher
├── settings.conf           # Persistent settings (auto-created)
├── README.md               # This file
└── logs/                  # Auto-created log directory
    ├── nexus_node_35835965.log
    ├── nexus_node_35837105.log
    └── ...
```

## Architecture

### Modular Design

The script uses a modular architecture for better maintainability:

- **Main Script**: Core functionality and menu interface
- **Resource Monitor Module**: All CPU/RAM monitoring functions
- **Settings Management**: Persistent configuration handling
- **Auto-Start System**: Inactivity detection and automatic node management

### Key Functions

- `get_total_submissions()` - Counts successful proofs across all nodes
- `show_system_resources()` - Detailed real-time resource monitoring
- `auto_start_all_nodes_on_inactivity()` - Smart auto-start functionality
- `toggle_all_half_nodes()` - Switch between all/half node modes
- `toggle_pause_resume_all()` - Pause/resume node operations

## Troubleshooting

### Common Issues

- **Nodes not starting**: Check if `nexus-network` is installed and in PATH
- **Permission denied**: Run `chmod +x launch_nexus_nodes.sh`
- **WSL sync issues**: Ensure WSL Ubuntu is running before using sync script
- **Resource monitor not working**: Ensure `resource_monitor.sh` is in the same directory
- **Settings not saving**: Check write permissions in the script directory

### Log Locations

- Individual node logs: `logs/nexus_node_[NODE_ID].log`
- Use option `5` to view successful submissions
- Use option `6` to access settings and cleanup options

### Performance Tips

- Use **Half Mode** (option 2) if system resources are limited
- Monitor resource usage with **System Resources** (option 9)
- Enable **Auto-Start** to ensure nodes resume after inactivity
- Use **Pause/Resume** (option 7) instead of stop/start for temporary interruptions

## Requirements

- Linux/WSL environment
- `nexus-network` command-line tool
- Bash shell
- Standard Unix utilities (`ps`, `grep`, `awk`, `du`, `free`, `top`, `bc`)
- Write permissions for settings file creation

## Safety Notes

- Option `0` (Stop All Processes) requires confirmation
- Log cleanup shows file sizes before deletion
- All destructive operations have confirmation prompts
- Live dashboards exit cleanly with 'q' or ESC key
- **Paused nodes are detected** - Script prevents starting new nodes when others are paused
- **Auto-start respects node state** - Won't interfere with manual operations

## Advanced Features

### Inactivity Detection

The script uses exact timeout tracking rather than log file modification times:

- **Activation File**: `.auto_start_activation` tracks when auto-start was activated
- **Precise Timing**: Triggers exactly after the configured timeout period
- **State Awareness**: Handles different node states appropriately
- **Visual Feedback**: Countdown timer on main menu

### Resource Monitoring

Comprehensive resource tracking with modular architecture:

- **Script Resources**: CPU and memory usage of the manager script
- **Node Resources**: Aggregated usage across all nexus nodes
- **System Resources**: Overall system resource availability
- **Smart Formatting**: Human-readable memory sizes (GB/MB/KB)
- **Real-Time Updates**: Auto-refreshing displays with user control

### Settings Persistence

All configuration changes are automatically saved:

- **Automatic Saving**: Settings are saved immediately when changed
- **Persistent State**: Your preferences survive script restarts
- **Default Fallbacks**: Sensible defaults if settings file is missing
- **Error Handling**: Graceful handling of corrupted settings files
