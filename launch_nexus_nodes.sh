#!/bin/bash

# Nexus Network Node Launcher - Menu Version
# This script provides a menu to manage nexus-network processes

# Array of node IDs from the nexus.txt file
node_ids=(
    "35835965"
    "35837105"
    "35924545"
    "35785219"
    "35900259"
    "35924549"
    "35785224"
    "35754765"
    "36706792"
    "36786325"
    "36727116"
    "36680912"
)

# Setting: Auto-clean logs on startup (loaded from settings file)
# Default will be used if settings file doesn't exist
AUTO_CLEAN_LOGS=false

# Setting: Auto start on inactivity (minutes)
# Will automatically start/resume nodes if inactive for specified time
AUTO_START_INACTIVITY=true
INACTIVITY_TIMEOUT=1  # minutes

# Settings file path
SETTINGS_FILE="settings.conf"

# Global variables for tracking node states (cached for efficiency)
CACHED_RUNNING_COUNT=0
CACHED_PAUSED_COUNT=0
CACHE_VALID=false

# Function to get last activity time from logs
get_last_activity_time() {
    local latest_time=0
    
    for log_file in logs/nexus_node_*.log; do
        if [ -f "$log_file" ]; then
            # Get the last modification time of the log file
            file_time=$(stat -c %Y "$log_file" 2>/dev/null)
            if [ "$file_time" -gt "$latest_time" ]; then
                latest_time=$file_time
            fi
        fi
    done
    
    echo $latest_time
}

# Function to check if nodes have been inactive
check_inactivity() {
    if [ "$AUTO_START_INACTIVITY" = false ]; then
        return 1  # Feature disabled
    fi
    
    # Get current time and last activity time
    current_time=$(date +%s)
    last_activity=$(get_last_activity_time)
    
    if [ "$last_activity" -eq 0 ]; then
        return 0  # No activity found, treat as inactive
    fi
    
    # Calculate minutes since last activity
    inactive_minutes=$(( (current_time - last_activity) / 60 ))
    
    if [ "$inactive_minutes" -ge "$INACTIVITY_TIMEOUT" ]; then
        echo -e "\033[1;33m⏰ Inactivity detected: $inactive_minutes minutes since last activity\033[0m"
        return 0  # Inactive
    else
        return 1  # Active
    fi
}

# Function to auto-start on inactivity
auto_start_on_inactivity() {
    if ! check_inactivity; then
        return 0  # No inactivity, nothing to do
    fi
    
    echo -e "\033[1;33m🚀 Auto-starting nodes due to inactivity...\033[0m"
    echo ""
    
    # Update cache first
    update_node_state_cache
    
    if [ $CACHED_PAUSED_COUNT -gt 0 ]; then
        echo -e "\033[1;32m▶️  Auto-resuming $CACHED_PAUSED_COUNT paused nodes...\033[0m"
        resume_all_nodes_internal
        invalidate_cache_and_refresh
    elif [ $CACHED_RUNNING_COUNT -eq 0 ]; then
        echo -e "\033[1;32m📋 Auto-starting all nodes (none running)...\033[0m"
        launch_nexus_processes "all"
    else
        echo -e "\033[1;36mℹ️  Nodes already running, no action needed\033[0m"
    fi
    
    echo ""
    echo -e "\033[1;32m✅ Auto-start completed!\033[0m"
    echo "Press Enter to continue..."
    read
}

# Function to update cached node state counts
update_node_state_cache() {
    CACHED_RUNNING_COUNT=0
    CACHED_PAUSED_COUNT=0
    
    for node_id in "${node_ids[@]}"; do
        if check_node_running "$node_id"; then
            CACHED_RUNNING_COUNT=$((CACHED_RUNNING_COUNT + 1))
        elif check_node_paused "$node_id"; then
            CACHED_PAUSED_COUNT=$((CACHED_PAUSED_COUNT + 1))
        fi
    done
    
    CACHE_VALID=true
}

# Function to load settings from file
load_settings() {
    if [ -f "$SETTINGS_FILE" ]; then
        # Source the settings file
        source "$SETTINGS_FILE"
        echo -e "\033[1;32m✅ Settings loaded from $SETTINGS_FILE\033[0m"
    else
        echo -e "\033[1;33m⚠️  Settings file not found, using defaults\033[0m"
    fi
}

# Function to save settings to file
save_settings() {
    cat > "$SETTINGS_FILE" <<EOF
# Nexus Network Node Manager Settings
# Generated automatically - do not edit manually

# Auto-clean logs on startup (true/false)
AUTO_CLEAN_LOGS=$AUTO_CLEAN_LOGS

# Auto start on inactivity (true/false)
AUTO_START_INACTIVITY=$AUTO_START_INACTIVITY

# Inactivity timeout in minutes
INACTIVITY_TIMEOUT=$INACTIVITY_TIMEOUT
EOF
    echo -e "\033[1;32m✅ Settings saved to $SETTINGS_FILE\033[0m"
}

# Reusable functions for common operations

# Function to check if specific node is already running (not paused)
check_node_running() {
    local node_id=$1
    # Check if process exists and is NOT in "T" (stopped) state
    ps aux | grep "nexus-network.*--node-id $node_id" | grep -v grep | grep -v "T" | grep -q "."
}

# Function to check if specific node is paused
check_node_paused() {
    local node_id=$1
    # A paused process exists but is in "T" (stopped) state
    ps aux | grep "nexus-network.*--node-id $node_id" | grep -v grep | grep -q "T"
}

# Function to pause specific node
pause_node() {
    local node_id=$1
    echo -e "\033[1;33m⏸️  Pausing Node $node_id...\033[0m"
    
    # Send SIGSTOP to pause the process
    pkill -SIGSTOP -f "nexus-network.*--node-id $node_id"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Node $node_id paused successfully\033[0m"
        echo -e "\033[1;36m💡 Use 'Resume Nodes' option to unpause\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Failed to pause Node $node_id\033[0m"
        echo -e "\033[1;33m⚠️  Node may not be running\033[0m"
        return 1
    fi
}

# Function to unpause specific node
unpause_node() {
    local node_id=$1
    echo -e "\033[1;32m▶️  Resuming Node $node_id...\033[0m"
    
    # Send SIGCONT to resume the process
    pkill -SIGCONT -f "nexus-network.*--node-id $node_id"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m✅ Node $node_id resumed successfully\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Failed to resume Node $node_id\033[0m"
        echo -e "\033[1;33m⚠️  Node may not be paused\033[0m"
        return 1
    fi
}

# Function to toggle pause/resume for all nodes
toggle_pause_resume_all() {
    echo "Toggle Pause/Resume All Nodes"
    echo "=============================="
    echo ""
    
    # Use cached values - update only if cache is invalid
    if [ "$CACHE_VALID" = false ]; then
        update_node_state_cache
    fi
    
    echo -e "\033[1;36m📊 Current Node Status:\033[0m"
    echo -e "   Running: \033[1;32m$CACHED_RUNNING_COUNT\033[0m"
    echo -e "   Paused:  \033[1;33m$CACHED_PAUSED_COUNT\033[0m"
    echo -e "   Stopped: \033[1;31m$((12 - CACHED_RUNNING_COUNT - CACHED_PAUSED_COUNT))\033[0m"
    echo ""
    
    if [ $CACHED_RUNNING_COUNT -gt 0 ]; then
        echo -e "\033[1;33m⏸️  Pausing $CACHED_RUNNING_COUNT running nodes...\033[0m"
        pause_all_nodes_internal
        invalidate_cache_and_refresh
    elif [ $CACHED_PAUSED_COUNT -gt 0 ]; then
        echo -e "\033[1;32m▶️  Resuming $CACHED_PAUSED_COUNT paused nodes...\033[0m"
        resume_all_nodes_internal
        invalidate_cache_and_refresh
    else
        echo -e "\033[1;31m❌ No nodes are running or paused to toggle!\033[0m"
        echo -e "\033[1;36m💡 Start some nodes first using option 1 or 2\033[0m"
    fi
}

# Function to pause all running nodes (internal)
pause_all_nodes_internal() {
    paused_count=0
    failed_count=0
    
    for node_id in "${node_ids[@]}"; do
        if check_node_running "$node_id"; then
            if pause_node "$node_id"; then
                paused_count=$((paused_count + 1))
            else
                failed_count=$((failed_count + 1))
            fi
        fi
    done
    
    echo "=========================================="
    echo -e "\033[1;32m✅ Paused: $paused_count nodes\033[0m"
    echo -e "\033[1;31m❌ Failed: $failed_count nodes\033[0m"
    echo ""
}

# Function to resume all paused nodes (internal)
resume_all_nodes_internal() {
    resumed_count=0
    failed_count=0
    
    for node_id in "${node_ids[@]}"; do
        if check_node_paused "$node_id"; then
            if unpause_node "$node_id"; then
                resumed_count=$((resumed_count + 1))
            else
                failed_count=$((failed_count + 1))
            fi
        fi
    done
    
    echo "=========================================="
    echo -e "\033[1;32m✅ Resumed: $resumed_count nodes\033[0m"
    echo -e "\033[1;31m❌ Failed: $failed_count nodes\033[0m"
    echo ""
}

# Function to check if logs directory and files exist
check_logs_status() {
    local check_type=$1  # "directory" or "files"
    
    if [ "$check_type" = "directory" ]; then
        [ -d "logs" ]
    elif [ "$check_type" = "files" ]; then
        [ -d "logs" ] && ls logs/nexus_node_*.log 1> /dev/null 2>&1
    fi
}

# Function to show log file sizes
show_log_sizes() {
    local show_header=$1
    
    if [ "$show_header" = true ]; then
        echo -e "\033[1;36m📄 Individual log file sizes:\033[0m"
    fi
    
    for log_file in logs/nexus_node_*.log; do
        if [ -f "$log_file" ]; then
            file_size=$(du -sh "$log_file" 2>/dev/null | cut -f1)
            node_id=$(basename "$log_file" .log | sed 's/nexus_node_//')
            echo -e "   Node $node_id: \033[1;33m$file_size\033[0m"
        fi
    done
}

# Function to handle user input with 'q' to exit
handle_user_input() {
    local prompt=$1
    
    if [ -n "$prompt" ]; then
        echo -e "\033[1;33m$prompt\033[0m"
    fi
    
    if read -r -p ""; then
        [[ "$REPLY" =~ ^[qQ]$ ]]
    else
        false
    fi
}

# Function to show error message and wait for input
show_error_and_wait() {
    local message=$1
    echo -e "\033[1;33m⚠️  $message\033[0m"
    echo ""
    handle_user_input "Press 'q' to return to menu"
}

# Function to calculate total log directory size
get_logs_size() {
    du -sh logs 2>/dev/null | cut -f1
}

# Function to check if any nodes are paused (using cached values for efficiency)
check_any_nodes_paused() {
    # Return true if cached paused count is greater than 0
    [ $CACHED_PAUSED_COUNT -gt 0 ]
}

# Function to show paused nodes warning
show_paused_nodes_warning() {
    echo -e "\033[1;33m⚠️  PAUSED NODES DETECTED!\033[0m"
    echo ""
    echo -e "\033[1;36m📋 Nodes are paused. Use option 7 to resume them first.\033[0m"
    echo ""
    echo -e "\033[1;33m💡 To continue, please:\033[0m"
    echo -e "   1. Choose option 7 to \033[1;32mResume All Paused Nodes\033[0m"
    echo -e "   2. Or choose option 0 to \033[1;31mStop All Processes\033[0m"
    echo ""
    echo -e "\033[1;33m❌ Cannot start new nodes while others are paused.\033[0m"
    echo ""
}

# Function to launch nexus network processes (supports all or half mode)
launch_nexus_processes() {
    local mode=${1:-"all"}  # Default to "all" if no parameter
    
    # Check if any nodes are paused first
    if check_any_nodes_paused; then
        show_paused_nodes_warning
        echo "Press Enter to continue..."
        read
        return
    fi
    
    mkdir -p logs
    
    # Auto-clean logs if setting is true
    if [ "$AUTO_CLEAN_LOGS" = true ]; then
        echo -e "\033[1;33m🧹 Auto-cleaning logs (AUTO_CLEAN_LOGS=true)...\033[0m"
        
        # Check which nodes are running
        running_nodes=()
        for node_id in "${node_ids[@]}"; do
            if check_node_running "$node_id"; then
                running_nodes+=("$node_id")
            fi
        done
        
        if check_logs_status "files"; then
            echo -e "\033[1;36m📄 Existing log files found:\033[0m"
            show_log_sizes false
            
            # Delete log files only for nodes that are NOT running
            deleted_count=0
            preserved_count=0
            for log_file in logs/nexus_node_*.log; do
                if [ -f "$log_file" ]; then
                    node_id=$(basename "$log_file" .log | sed 's/nexus_node_//')
                    
                    # Check if this node is currently running
                    if [[ " ${running_nodes[*]} " =~ " ${node_id} " ]]; then
                        echo -e "\033[1;33m� Preserving log for running Node $node_id\033[0m"
                        preserved_count=$((preserved_count + 1))
                    else
                        echo -e "\033[1;31m🗑️  Deleting log for stopped Node $node_id\033[0m"
                        rm -f "$log_file"
                        deleted_count=$((deleted_count + 1))
                    fi
                fi
            done
            
            echo ""
            echo -e "\033[1;32m✅ Log cleanup completed:\033[0m"
            echo -e "   Deleted: \033[1;31m$deleted_count\033[0m log files"
            echo -e "   Preserved: \033[1;32m$preserved_count\033[0m log files (running nodes)"
        else
            echo -e "\033[1;32m✅ No existing log files found.\033[0m"
        fi
        
        echo ""
    fi
    
    # Calculate how many nodes to launch
    total_nodes=${#node_ids[@]}
    
    if [ "$mode" = "half" ]; then
        nodes_to_launch=$(( (total_nodes + 1) / 2 ))
        mode_desc="Resource-Saving Mode"
        mode_color="32"
        tip_msg="💡 Tip: Use option 1 to start remaining nodes if needed."
    else
        nodes_to_launch=$total_nodes
        mode_desc="All Nodes"
        mode_color="34"
        tip_msg="💡 Tip: Use option 2 for resource-saving mode."
    fi
    
    echo -e "\033[1;36m📊 Configuration:\033[0m"
    echo -e "   Total nodes available: \033[1;34m$total_nodes\033[0m"
    echo -e "   Nodes to launch: \033[1;$mode_color${nodes_to_launch}\033[0m ($mode_desc)"
    echo ""
    
    # Launch the nodes
    if [ "$mode" = "half" ]; then
        echo -e "\033[1;32m🚀 Launching first $nodes_to_launch nodes...\033[0m"
        end_index=$nodes_to_launch
    else
        echo -e "\033[1;32m🚀 Launching all $nodes_to_launch nodes...\033[0m"
        end_index=$total_nodes
    fi
    
    for ((i=0; i<$end_index; i++)); do
        node_id=${node_ids[$i]}
        
        # Check if this specific node is already running
        if check_node_running "$node_id"; then
            echo -e "\033[1;33m⚠️  Node $node_id is already running! Skipping...\033[0m"
            echo -e "\033[1;36m💡 Tip: Use option 0 to stop all processes first.\033[0m"

        else
            echo -e "\033[1;36m📋 Starting Node $node_id...\033[0m"
            
            # Start nexus-network in background with nohup, redirecting output to log file
            nohup nexus-network start --headless --node-id "$node_id" > "logs/nexus_node_$node_id.log" 2>&1 &
            
            # Add a small delay to prevent overwhelming the system
            sleep 1
        fi
    done
    
    echo ""
    # Count actual started nodes vs skipped nodes
    started_count=0
    skipped_running=0
    skipped_paused=0
    
    for ((i=0; i<$end_index; i++)); do
        node_id=${node_ids[$i]}
        if check_node_running "$node_id"; then
            skipped_running=$((skipped_running + 1))
        elif check_node_paused "$node_id"; then
            skipped_paused=$((skipped_paused + 1))
        else
            started_count=$((started_count + 1))
        fi
    done
    
    if [ "$mode" = "half" ]; then
        echo -e "\033[1;32m✅ Resource-Saving Mode Launch Complete:\033[0m"
    else
        echo -e "\033[1;32m✅ All Nodes Launch Complete:\033[0m"
    fi
    
    echo -e "   Started: \033[1;32m$started_count\033[0m new nodes"
    if [ $skipped_running -gt 0 ]; then
        echo -e "   Skipped: \033[1;33m$skipped_running\033[0m already running"
    fi
    if [ $skipped_paused -gt 0 ]; then
        echo -e "   Skipped: \033[1;33m$skipped_paused\033[0m paused nodes"
    fi
    
    if [ $started_count -gt 0 ]; then
        echo "Logs are being saved in 'logs' directory."
        if [ "$AUTO_CLEAN_LOGS" = true ]; then
            echo -e "\033[1;33m💡 Auto-cleanup is enabled - logs will be cleaned on next start.\033[0m"
        else
            echo -e "\033[1;32m💡 Auto-cleanup is disabled - logs will accumulate.\033[0m"
        fi
    fi
    
    echo -e "\033[1;33m$tip_msg\033[0m"
    echo ""
    
    # Invalidate cache since node states may have changed
    CACHE_VALID=false
}

# Function to stop all nexus processes
stop_all_nexus_processes() {
    echo "Stopping all Nexus Network processes..."
    echo "======================================"
    echo ""
    
    # Show current running processes first
    processes=$(ps aux | grep "nexus-network start" | grep -v grep)
    if [ -z "$processes" ]; then
        echo -e "\033[1;33m⚠️  No Nexus Network processes are currently running.\033[0m"
        echo ""
        return
    fi
    
    echo -e "\033[1;31m⚠️  WARNING: This will stop ALL running Nexus Network processes!\033[0m"
    echo ""
    echo -e "\033[1;36m📋 Currently running processes:\033[0m"
    echo "$processes" | while read line; do
        pid=$(echo "$line" | awk '{print $2}')
        echo -e "   PID: \033[1;33m$pid\033[0m"
    done
    echo ""
    
    # Ask for confirmation
    echo -e "\033[1;34mAre you sure you want to stop all processes? (y/N):\033[0m"
    read -r confirm
    
    case $confirm in
        [Yy]* )
            echo ""
            echo -e "\033[1;31m🛑 Stopping all Nexus Network processes...\033[0m"
            
            # Find and kill all nexus-network processes
            pkill -f "nexus-network start"
            
            # Wait a moment for processes to terminate
            sleep 2
            
            # Check if any processes are still running
            remaining_processes=$(ps aux | grep "nexus-network start" | grep -v grep | wc -l)
            
            if [ "$remaining_processes" -eq 0 ]; then
                echo -e "\033[1;32m✓ All Nexus Network processes stopped successfully!\033[0m"
                invalidate_cache_and_refresh
            else
                echo -e "\033[1;33m⚠ Some processes may still be running. Trying force kill...\033[0m"
                pkill -9 -f "nexus-network start"
                sleep 1
                remaining_processes=$(ps aux | grep "nexus-network start" | grep -v grep | wc -l)
                if [ "$remaining_processes" -eq 0 ]; then
                    echo -e "\033[1;32m✓ All processes force-killed!\033[0m"
                    invalidate_cache_and_refresh
                else
                    echo -e "\033[1;31m⚠ $remaining_processes processes still running. You may need to kill them manually.\033[0m"
                fi
            fi
            ;;
        * )
            echo ""
            echo -e "\033[1;33m❌ Process stop cancelled.\033[0m"
            ;;
    esac
    
    echo ""
}

# Function to delete large log files
cleanup_logs() {
    echo "Log Cleanup Utility"
    echo "==================="
    echo ""
    
    if ! check_logs_status "directory"; then
        show_error_and_wait "Logs directory not found."
        return
    fi
    
    # Check total size of logs directory
    total_size=$(get_logs_size)
    echo -e "\033[1;36m📁 Current logs directory size: \033[1;34m$total_size\033[0m"
    echo ""
    
    # Show individual log file sizes
    show_log_sizes true
    
    echo ""
    echo -e "\033[1;31m⚠️  WARNING: This will permanently delete all log files!\033[0m"
    echo -e "\033[1;33m💡 Tip: Consider backing up important logs before cleanup.\033[0m"
    echo ""
    
    # Ask for confirmation
    echo -e "\033[1;34mDelete all log files? (y/N):\033[0m"
    read -r confirm
    
    case $confirm in
        [Yy]* )
            echo ""
            echo -e "\033[1;31m🗑️  Deleting log files...\033[0m"
            
            # Delete log files
            rm -f logs/nexus_node_*.log
            
            echo -e "\033[1;32m✅ All log files deleted successfully!\033[0m"
            echo ""
            
            # Show new directory size
            if [ -d "logs" ] && [ "$(ls -A logs)" ]; then
                new_size=$(get_logs_size)
                echo -e "\033[1;36m📁 New logs directory size: \033[1;34m$new_size\033[0m"
            else
                echo -e "\033[1;36m📁 Logs directory is now empty.\033[0m"
            fi
            ;;
        * )
            echo ""
            echo -e "\033[1;33m❌ Log cleanup cancelled.\033[0m"
            ;;
    esac
    
    echo ""
}

# Function to display successful submissions from logs
show_successful_submissions() {
    while true; do
        clear
        echo "=========================================="
        echo "    Nexus Network Submissions Monitor"
        echo "=========================================="
        echo "Last Updated: $(date)"
        echo ""
        
        if ! check_logs_status "directory"; then
            show_error_and_wait "Logs directory not found. Please start the nodes first."
            continue
        fi
        
        if ! check_logs_status "files"; then
            show_error_and_wait "No log files found. Please start the nodes first."
            continue
        fi
        
        echo -e "\033[1;32m✅ Successful Submissions Summary:\033[0m"
        echo ""
        
        found_any=false
        total_submissions=0
        
        # Search through all log files for successful submissions
        for log_file in logs/nexus_node_*.log; do
            if [ -f "$log_file" ]; then
                node_id=$(basename "$log_file" .log | sed 's/nexus_node_//')
                submissions=$(grep -i "Proof submitted successfully for task" "$log_file" 2>/dev/null)
                count=$(echo "$submissions" | grep -c .)
                
                if [ "$count" -gt 0 ]; then
                    echo -e "\033[1;36m📋 Node $node_id:\033[0m \033[1;32m$count\033[0m successful submissions"
                    found_any=true
                    total_submissions=$((total_submissions + count))
                else
                    echo -e "\033[1;36m📋 Node $node_id:\033[0m \033[1;33m0\033[0m successful submissions"
                fi
            fi
        done
        
        if [ "$found_any" = false ]; then
            echo -e "\033[1;33m⚠️  No successful submissions found in any logs.\033[0m"
            echo ""
            echo -e "\033[1;36m💡 Tip: Make sure nodes are running and have had time to process tasks.\033[0m"
        else
            echo ""
            echo -e "\033[1;34m📊 Summary:\033[0m"
            echo -e "   Total successful submissions across all nodes: \033[1;32m$total_submissions\033[0m"
            echo -e "   Active nodes: \033[1;34m$(ls logs/nexus_node_*.log | wc -l)\033[0m"
        fi
        
        echo ""
        echo -e "\033[1;36m📁 Log files location: ./logs/\033[0m"
        echo ""
        echo -e "\033[1;36m🔄 Auto-refreshing every 30 seconds...\033[0m"
        echo -e "\033[1;33mPress 'q' or ESC to return to menu\033[0m"
        echo ""
        
        # Use read with timeout and check for 'q' or ESC input
        if read -t 30 -r -p ""; then
            if [[ "$REPLY" =~ ^[qQ]$ ]] || [ "$REPLY" = $'\e' ]; then
                echo -e "\n\033[1;33m🔄 Returning to main menu...\033[0m"
                break
            fi
        fi
    done
}
# Function to display process information with colors (reusable function)
display_process_info() {
    local show_header=$1
    
    # Get only running processes (exclude paused ones with "T" state)
    running_processes=$(ps aux | grep "nexus-network.*--node-id" | grep -v grep | grep -v "T")
    # Get paused processes (those with "T" state)
    paused_processes=$(ps aux | grep "nexus-network.*--node-id" | grep -v grep | grep "T")
    
    if [ -z "$running_processes" ] && [ -z "$paused_processes" ]; then
        echo -e "\033[1;31m❌ No Nexus Network processes are currently running.\033[0m"
        if [ "$show_header" = "dashboard" ]; then
            echo ""
            echo -e "\033[1;33m💡 Tip: Use option 1 to start all processes\033[0m"
        fi
        return 1
    else
        # Display running processes
        if [ -n "$running_processes" ]; then
            if [ "$show_header" = "dashboard" ]; then
                echo -e "\033[1;32m✅ Running Nexus Network Processes:\033[0m"
            else
                echo -e "\033[1;32m✅ Running processes with CPU and Memory usage:\033[0m"
            fi
            echo ""
            echo -e "\033[1;36mUSER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\033[0m"
            
            # Color code each process based on CPU usage
            echo "$running_processes" | while read line; do
                cpu_usage=$(echo "$line" | awk '{print $3}')
                if (( $(echo "$cpu_usage > 50" | bc -l) )); then
                    # High CPU usage - Red
                    echo -e "\033[1;31m$line\033[0m"
                elif (( $(echo "$cpu_usage > 20" | bc -l) )); then
                    # Medium CPU usage - Yellow
                    echo -e "\033[1;33m$line\033[0m"
                else
                    # Normal CPU usage - Green
                    echo -e "\033[1;32m$line\033[0m"
                fi
            done
        fi
        
        # Display paused processes
        if [ -n "$paused_processes" ]; then
            if [ -n "$running_processes" ]; then
                echo ""
            fi
            echo -e "\033[1;33m⏸️  Paused Nexus Network Processes:\033[0m"
            echo ""
            echo -e "\033[1;36mUSER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\033[0m"
            
            # Show paused processes in yellow/orange
            echo "$paused_processes" | while read line; do
                echo -e "\033[1;33m$line\033[0m"
            done
        fi
    fi
    
    # Show statistics if there are any processes
    if [ -n "$running_processes" ] || [ -n "$paused_processes" ]; then
        echo ""
        
        # Count total processes
        running_count=$(echo "$running_processes" | wc -l)
        paused_count=$(echo "$paused_processes" | wc -l)
        total_count=$((running_count + paused_count))
        
        if [ "$show_header" = "dashboard" ]; then
            echo -e "\033[1;36m📊 Statistics:\033[0m"
            echo -e "   Running processes: \033[1;32m$running_count\033[0m"
            if [ $paused_count -gt 0 ]; then
                echo -e "   Paused processes: \033[1;33m$paused_count\033[0m"
            fi
            echo -e "   Total processes: \033[1;34m$total_count\033[0m"
        else
            echo -e "\033[1;36m📊 Process Summary:\033[0m"
            echo -e "   Running: \033[1;32m$running_count\033[0m"
            if [ $paused_count -gt 0 ]; then
                echo -e "   Paused: \033[1;33m$paused_count\033[0m"
            fi
            echo -e "   Total: \033[1;34m$total_count\033[0m"
        fi
        
        # Show total CPU usage for running processes only
        if [ -n "$running_processes" ]; then
            total_cpu=$(echo "$running_processes" | awk '{sum += $3} END {printf "%.1f", sum}')
            if (( $(echo "$total_cpu > 100" | bc -l) )); then
                echo -e "   \033[1;31m⚠️  High CPU usage: ${total_cpu}%\033[0m"
            elif (( $(echo "$total_cpu > 50" | bc -l) )); then
                echo -e "   \033[1;33m⚠️  Moderate CPU usage: ${total_cpu}%\033[0m"
            else
                echo -e "   \033[1;32m✅ Normal CPU usage: ${total_cpu}%\033[0m"
            fi
        fi
        return 0
    fi
}

# Function to display real-time dashboard
show_realtime_dashboard() {
    while true; do
        clear
        echo "=========================================="
        echo "    Nexus Network Real-Time Dashboard"
        echo "=========================================="
        echo "Last Updated: $(date)"
        echo ""
        
        display_process_info "dashboard"
        
        echo ""
        echo -e "\033[1;36m🔄 Auto-refreshing every 10 seconds...\033[0m"
        echo -e "\033[1;33mPress 'q' or ESC to return to menu\033[0m"
        echo ""
        
        # Use read with timeout and check for 'q' or ESC input
        if read -t 30 -r -p ""; then
            if [[ "$REPLY" =~ ^[qQ]$ ]] || [ "$REPLY" = $'\e' ]; then
                echo -e "\n\033[1;33m🔄 Returning to main menu...\033[0m"
                break
            fi
        fi
    done
}

# Function to check running processes (static version)
check_running_processes() {
    echo "Checking running Nexus Network processes..."
    echo "==========================================="
    echo ""
    
    display_process_info "static"
    echo ""
}

# Function to display settings menu
display_settings_menu() {
    clear
    echo "=========================================="
    echo "    Nexus Network Settings"
    echo "=========================================="
    echo ""
    echo -e "\033[1;34m1.\033[0m Auto-Clean Logs at startup: \033[1;33m$AUTO_CLEAN_LOGS\033[0m"
    echo -e "\033[1;34m2.\033[0m Auto-Start on Inactivity: \033[1;33m$AUTO_START_INACTIVITY\033[0m (\033[1;36m$INACTIVITY_TIMEOUT minutes\033[0m)"
    echo -e "\033[1;34m3.\033[0m Clean Up Logs (delete large files)"
    echo -e "\033[1;34m4.\033[0m Return to Main Menu"
    echo ""
    echo "=========================================="
    echo -n "Please select an option [1-4]: "
}

# Function to toggle auto-start inactivity setting
toggle_auto_start_inactivity() {
    echo "Auto-Start on Inactivity Setting"
    echo "================================="
    echo ""
    echo -e "Current setting: \033[1;33m$AUTO_START_INACTIVITY\033[0m"
    echo -e "Current timeout: \033[1;36m$INACTIVITY_TIMEOUT minutes\033[0m"
    echo ""
    echo "When enabled, nodes will automatically start/resume if inactive for the specified time."
    echo "This helps ensure your nodes are always working and earning rewards."
    echo ""
    
    if [ "$AUTO_START_INACTIVITY" = true ]; then
        echo -e "\033[1;33m⚠️  Auto-start is currently ENABLED\033[0m"
        echo ""
        echo -e "\033[1;34mChoose new setting:\033[0m"
        echo "1. Disable auto-start"
        echo "2. Change timeout (current: $INACTIVITY_TIMEOUT minutes)"
        echo "3. Cancel"
        echo ""
        echo -n "Please select an option [1-3]: "
        read choice
        
        case $choice in
            1)
                AUTO_START_INACTIVITY=false
                echo -e "\033[1;31m❌ Auto-start on inactivity DISABLED\033[0m"
                save_settings
                ;;
            2)
                echo ""
                echo -n "Enter new timeout in minutes (5-1440): "
                read new_timeout
                if [[ "$new_timeout" =~ ^[0-9]+$ ]] && [ "$new_timeout" -ge 5 ] && [ "$new_timeout" -le 1440 ]; then
                    INACTIVITY_TIMEOUT=$new_timeout
                    echo -e "\033[1;32m✅ Timeout updated to $INACTIVITY_TIMEOUT minutes\033[0m"
                    save_settings
                else
                    echo -e "\033[1;31m❌ Invalid timeout. Please enter a number between 5 and 1440.\033[0m"
                fi
                ;;
            3)
                echo -e "\033[1;33m❌ Setting unchanged\033[0m"
                ;;
            *)
                echo -e "\033[1;31m❌ Invalid option\033[0m"
                ;;
        esac
    else
        echo -e "\033[1;33m⚠️  Auto-start is currently DISABLED\033[0m"
        echo ""
        echo -e "\033[1;34mChoose new setting:\033[0m"
        echo "1. Enable auto-start"
        echo "2. Change timeout (current: $INACTIVITY_TIMEOUT minutes)"
        echo "3. Cancel"
        echo ""
        echo -n "Please select an option [1-3]: "
        read choice
        
        case $choice in
            1)
                AUTO_START_INACTIVITY=true
                echo -e "\033[1;32m✅ Auto-start on inactivity ENABLED\033[0m"
                save_settings
                ;;
            2)
                echo ""
                echo -n "Enter new timeout in minutes (1-1440): "
                read new_timeout
                if [[ "$new_timeout" =~ ^[0-9]+$ ]] && [ "$new_timeout" -ge 1 ] && [ "$new_timeout" -le 1440 ]; then
                    INACTIVITY_TIMEOUT=$new_timeout
                    echo -e "\033[1;32m✅ Timeout updated to $INACTIVITY_TIMEOUT minutes\033[0m"
                    save_settings
                else
                    echo -e "\033[1;31m❌ Invalid timeout. Please enter a number between 1 and 1440.\033[0m"
                fi
                ;;
            3)
                echo -e "\033[1;33m❌ Setting unchanged\033[0m"
                ;;
            *)
                echo -e "\033[1;31m❌ Invalid option\033[0m"
                ;;
        esac
    fi
}

# Function to toggle auto-clean logs setting
toggle_auto_clean_logs() {
    echo "Auto-Clean Logs Setting"
    echo "======================"
    echo ""
    echo -e "Current setting: \033[1;33m$AUTO_CLEAN_LOGS\033[0m"
    echo ""
    echo "When enabled, logs are automatically cleaned on startup."
    echo "When disabled, logs accumulate until manually cleaned."
    echo ""
    echo -e "\033[1;34mToggle setting? (y/N):\033[0m"
    read -r confirm
    
    case $confirm in
        [Yy]* )
            if [ "$AUTO_CLEAN_LOGS" = true ]; then
                AUTO_CLEAN_LOGS=false
                echo -e "\033[1;31m❌ Auto-clean logs DISABLED\033[0m"
            else
                AUTO_CLEAN_LOGS=true
                echo -e "\033[1;32m✅ Auto-clean logs ENABLED\033[0m"
            fi
            echo -e "\033[1;33m💡 Setting will take effect on next startup.\033[0m"
            echo ""
            # Save the updated setting to file
            save_settings
            ;;
        * )
            echo -e "\033[1;33m❌ Setting unchanged.\033[0m"
            ;;
    esac
    echo ""
}

# Function to handle settings menu
settings_menu() {
    while true; do
        display_settings_menu
        read choice
        echo ""
        
        case $choice in
            1)
                toggle_auto_clean_logs
                echo "Press Enter to continue..."
                read
                ;;
            2)
                toggle_auto_start_inactivity
                echo "Press Enter to continue..."
                read
                ;;
            3)
                cleanup_logs
                echo "Press Enter to continue..."
                read
                ;;
            4)
                break
                ;;
            *)
                echo -e "\033[1;31mInvalid option! Please select 1-4.\033[0m"
                echo "Press Enter to continue..."
                read
                ;;
        esac
    done
}

# Function to get current pause/resume menu text (using cached values for efficiency)
get_pause_resume_menu_text() {
    # Update cache if not valid to ensure accurate menu text
    if [ "$CACHE_VALID" = false ]; then
        update_node_state_cache
    fi
    
    if [ $CACHED_RUNNING_COUNT -gt 0 ]; then
        echo -e "\033[1;34m7.\033[0m \033[1;33mPause All Nodes\033[0m \033[1;32m($CACHED_RUNNING_COUNT running)\033[0m"
    elif [ $CACHED_PAUSED_COUNT -gt 0 ]; then
        echo -e "\033[1;34m7.\033[0m \033[1;32mResume All Nodes\033[0m \033[1;33m($CACHED_PAUSED_COUNT paused)\033[0m"
    else
        echo -e "\033[1;34m7.\033[0m \033[1;37mPause/Resume Nodes\033[0m \033[1;33m(No active nodes)\033[0m"
    fi
}

# Function to get time remaining until auto-start
get_auto_start_countdown() {
    if [ "$AUTO_START_INACTIVITY" = false ]; then
        return 0  # Feature disabled
    fi
    
    # Get current time and last activity time
    current_time=$(date +%s)
    last_activity=$(get_last_activity_time)
    
    if [ "$last_activity" -eq 0 ]; then
        echo "No activity detected"
        return 0
    fi
    
    # Calculate total seconds since last activity
    inactive_seconds=$((current_time - last_activity))
    timeout_seconds=$((INACTIVITY_TIMEOUT * 60))
    remaining_seconds=$((timeout_seconds - inactive_seconds))
    
    if [ "$remaining_seconds" -le 0 ]; then
        echo "Auto-starting now..."
    elif [ "$remaining_seconds" -lt 60 ]; then
        echo "$remaining_seconds seconds"
    else
        remaining_minutes=$((remaining_seconds / 60))
        remaining_secs=$((remaining_seconds % 60))
        if [ "$remaining_minutes" -eq 1 ]; then
            echo "1 minute $remaining_secs seconds"
        else
            echo "$remaining_minutes minutes $remaining_secs seconds"
        fi
    fi
}

# Function to invalidate cache and refresh menu
invalidate_cache_and_refresh() {
    CACHE_VALID=false
}

# Function to handle automatic return with manual override
auto_return_to_menu() {
    echo -e "\033[1;36m📋 Returning to main menu in 10 seconds... (or press Enter to return now)\033[0m"
    invalidate_cache_and_refresh
    if read -t 10 -r -p ""; then
        # User pressed Enter before timeout, return immediately
        echo ""
    fi
}

# Function to display menu
display_menu() {
    clear
    echo "=========================================="
    echo "    Nexus Network Node Manager"
    echo "=========================================="
    echo ""
    echo -e "\033[1;34m1.\033[0m Run Nexus Network Script (All Nodes)"
    echo -e "\033[1;34m2.\033[0m Run Half Nodes (Resource-Saving Mode)"
    echo -e "\033[1;34m3.\033[0m Check Running Processes"
    echo -e "\033[1;34m4.\033[0m \033[1;32mReal-Time Dashboard\033[0m \033[1;33m(Live Update)\033[0m"
    echo -e "\033[1;34m5.\033[0m \033[1;35mShow Successful Submissions\033[0m \033[1;33m(from logs)\033[0m"
    echo -e "\033[1;34m6.\033[0m Settings"
    get_pause_resume_menu_text
    echo -e "\033[1;34m8.\033[0m Exit \033[1;33m(or press ESC)\033[0m"
    echo ""
    echo -e "\033[1;34m0.\033[0m \033[1;31mStop All Nexus Processes\033[0m \033[1;33m(Force Kill)\033[0m"
    echo ""
    echo "=========================================="
    echo -e "\033[1;36m📋 Current Settings:\033[0m"
    echo -e "   Auto-Clean Logs: \033[1;33m$AUTO_CLEAN_LOGS\033[0m | Auto-Start: \033[1;33m$AUTO_START_INACTIVITY\033[0m (\033[1;36m$INACTIVITY_TIMEOUT min\033[0m)"
    
    # Show auto-start countdown if nodes are paused and auto-start is enabled
    if [ "$AUTO_START_INACTIVITY" = true ] && [ $CACHED_PAUSED_COUNT -gt 0 ]; then
        countdown=$(get_auto_start_countdown)
        echo -e "   \033[1;33m⏰ Auto-restart in: \033[1;31m$countdown\033[0m"
    fi
    
    echo "=========================================="
    echo -n "Please select an option [0-8]: "
}

# Main program loop
main() {
    # Load settings from file at startup
    load_settings
    echo ""
    
    # Initialize node state cache
    update_node_state_cache
    
    # Check for inactivity and auto-start if needed at startup
    if check_inactivity; then
        auto_start_on_inactivity
    fi
    
    while true; do
        # Check for inactivity before displaying menu
        if check_inactivity; then
            auto_start_on_inactivity
            invalidate_cache_and_refresh
        fi
        
        display_menu
        
        # Add a timeout to read command to allow periodic checking
        # This will check for input every 5 seconds
        if read -s -n 1 -t 5 choice 2>/dev/null; then
            echo ""
            
            # Check for ESC key (ASCII 27) or '8' for exit
            if [ "$choice" = $'\e' ] || [ "$choice" = "8" ]; then
                echo -e "\033[1;32m👋 Exiting Nexus Network Node Manager. Goodbye!\033[0m"
                exit 0
            fi
            
            # Process the choice if input was received
            case $choice in
            1)
                launch_nexus_processes "all"
                auto_return_to_menu
                ;;
            2)
                launch_nexus_processes "half"
                auto_return_to_menu
                ;;
            3)
                check_running_processes
                auto_return_to_menu
                ;;
            4)
                show_realtime_dashboard
                ;;
            5)
                show_successful_submissions
                echo "Press Enter to continue..."
                read
                ;;
            6)
                settings_menu
                ;;
            7)
                toggle_pause_resume_all
                auto_return_to_menu
                ;;
            0)
                stop_all_nexus_processes
                echo "Press Enter to continue..."
                read
                ;;
            *)
                echo -e "\033[1;31mInvalid option! Please select 0-7 or ESC to exit.\033[0m"
                echo "Press Enter to continue..."
                read
                ;;
        esac
        else
            # Read timed out (no input), continue loop to refresh menu and check inactivity
            echo ""
        fi
    done
}

# Start the program
main
