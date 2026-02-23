# Nexus Network Node Manager

A comprehensive bash script for managing multiple Nexus Network nodes with a user-friendly menu interface. Features real-time monitoring, log management, and live submission tracking.

## Files

- `launch_nexus_nodes.sh` - Main bash script with menu-driven interface
- `sync-to-wsl.ps1` - PowerShell script to sync shell files to WSL
- `Sync to WSL.bat` - Batch file for double-click execution
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

1. **Run Nexus Network Script** - Launch all configured nodes
2. **Check Running Processes** - Monitor CPU and memory usage
3. **Real-Time Dashboard** - Live auto-refreshing process monitor (3-second updates)
4. **Show Successful Submissions** - Live submission tracker (30-second updates)
5. **Clean Up Logs** - Delete log files when they get too large
6. **Exit** - Exit the manager

### Special Option

0. **Stop All Nexus Processes** - Emergency stop with confirmation (red option)

## Features

### 🚀 Node Management

- Launch multiple `nexus-network start --headless --node-id` processes
- Automatic log file creation for each node
- Configurable node IDs in the script
- Auto-cleanup option for logs on startup

### 📊 Real-Time Monitoring

- **Process Dashboard**: Live CPU/memory usage with color coding
- **Submission Monitor**: Track successful proofs per node
- Auto-refreshing displays with 'q' to exit
- Color-coded resource usage indicators

### 📝 Log Management

- Individual log files per node: `logs/nexus_node_[NODE_ID].log`
- Automatic log cleanup utility
- File size tracking and management
- Configurable auto-cleanup on startup

### 🛡️ Safety Features

- Confirmation prompts for destructive operations
- Process verification before stopping
- Graceful error handling
- Clean exit from live dashboards

## Configuration

### Node IDs

Edit the `node_ids` array in `launch_nexus_nodes.sh`:

```bash
node_ids=(
    "35835965"
    "35837105"
    "35924545"
    # Add more node IDs here
)
```

### Auto-Cleanup Setting

Toggle automatic log cleanup on startup:

```bash
AUTO_CLEAN_LOGS=true  # Set to false to disable
```

## Usage Examples

### Start All Nodes

1. Run the script: `./launch_nexus_nodes.sh`
2. Select option `1` to launch all nodes
3. Logs are automatically created in `logs/` directory

### Monitor Performance

1. Select option `3` for static process view
2. Select option `4` for real-time dashboard
3. Press 'q' to return to menu

### Track Submissions

1. Select option `5` for live submission monitor
2. Shows total successful proofs per node
3. Auto-refreshes every 30 seconds

### Emergency Stop

1. Select option `0` to stop all processes
2. Review running processes in the warning
3. Confirm with 'y' to proceed

## File Structure

```
nexus/
├── launch_nexus_nodes.sh    # Main script
├── sync-to-wsl.ps1         # WSL sync script
├── Sync to WSL.bat         # Double-click launcher
├── README.md               # This file
└── logs/                  # Auto-created log directory
    ├── nexus_node_35835965.log
    ├── nexus_node_35837105.log
    └── ...
```

## Troubleshooting

### Common Issues

- **Nodes not starting**: Check if `nexus-network` is installed and in PATH
- **Permission denied**: Run `chmod +x launch_nexus_nodes.sh`
- **WSL sync issues**: Ensure WSL Ubuntu is running before using sync script

### Log Locations

- Individual node logs: `logs/nexus_node_[NODE_ID].log`
- Use option `5` to view successful submissions
- Use option `6` to clean up large log files

## Requirements

- Linux/WSL environment
- `nexus-network` command-line tool
- Bash shell
- Standard Unix utilities (`ps`, `grep`, `awk`, `du`, etc.)

## Safety Notes

- Option `0` (Stop All Processes) requires confirmation
- Log cleanup shows file sizes before deletion
- All destructive operations have confirmation prompts
- Live dashboards exit cleanly with 'q' key
