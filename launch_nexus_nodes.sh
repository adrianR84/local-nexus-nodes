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

# Setting: Auto-clean logs on startup (default: true)
AUTO_CLEAN_LOGS=true

# Reusable functions for common operations

# Function to check if specific node is already running
check_node_running() {
    local node_id=$1
    ps aux | grep "nexus-network start" | grep -v grep | grep -q "nexus-network start.*--node-id $node_id"
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

# Function to launch nexus network processes (supports all or half mode)
launch_nexus_processes() {
    local mode=${1:-"all"}  # Default to "all" if no parameter
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
            echo -e "\033[1;36m� Tip: Use option 0 to stop all processes first.\033[0m"
        else
            echo -e "\033[1;36m�� Starting Node $node_id...\033[0m"
            
            # Start nexus-network in background with nohup, redirecting output to log file
            nohup nexus-network start --headless --node-id "$node_id" > "logs/nexus_node_$node_id.log" 2>&1 &
            
            # Add a small delay to prevent overwhelming the system
            sleep 1
        fi
    done
    
    echo ""
    if [ "$mode" = "half" ]; then
        echo -e "\033[1;32m✅ Resource-Saving Mode: $nodes_to_launch nodes started successfully!\033[0m"
    else
        echo -e "\033[1;32m✅ All $nodes_to_launch nodes started successfully!\033[0m"
        echo "Logs are being saved in 'logs' directory."
        if [ "$AUTO_CLEAN_LOGS" = true ]; then
            echo -e "\033[1;33m💡 Auto-cleanup is enabled - logs will be cleaned on next start.\033[0m"
        else
            echo -e "\033[1;32m💡 Auto-cleanup is disabled - logs will accumulate.\033[0m"
        fi
    fi
    echo -e "\033[1;33m$tip_msg\033[0m"
    echo ""
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
            else
                echo -e "\033[1;33m⚠ Some processes may still be running. Trying force kill...\033[0m"
                pkill -9 -f "nexus-network start"
                sleep 1
                remaining_processes=$(ps aux | grep "nexus-network start" | grep -v grep | wc -l)
                if [ "$remaining_processes" -eq 0 ]; then
                    echo -e "\033[1;32m✓ All processes force-killed!\033[0m"
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
        echo -e "\033[1;33mPress 'q' to return to menu\033[0m"
        echo ""
        
        # Use read with timeout and check for 'q' input
        if read -t 30 -r -p ""; then
            if [[ "$REPLY" =~ ^[qQ]$ ]]; then
                echo -e "\n\033[1;33m🔄 Returning to main menu...\033[0m"
                break
            fi
        fi
    done
}
# Function to display process information with colors (reusable function)
display_process_info() {
    local show_header=$1
    
    processes=$(ps aux | grep "nexus-network start" | grep -v grep)
    
    if [ -z "$processes" ]; then
        echo -e "\033[1;31m❌ No Nexus Network processes are currently running.\033[0m"
        if [ "$show_header" = "dashboard" ]; then
            echo ""
            echo -e "\033[1;33m💡 Tip: Use option 1 to start all processes\033[0m"
        fi
        return 1
    else
        if [ "$show_header" = "dashboard" ]; then
            echo -e "\033[1;32m✅ Running Nexus Network Processes:\033[0m"
        else
            echo -e "\033[1;32m✅ Running processes with CPU and Memory usage:\033[0m"
        fi
        echo ""
        echo -e "\033[1;36mUSER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\033[0m"
        
        # Color code each process based on CPU usage
        echo "$processes" | while read line; do
            cpu_usage=$(echo "$line" | awk '{print $3}')
            if (( $(echo "$cpu_usage > 50" | bc -l) )); then
                # High CPU usage - Red
                echo -e "\033[1;31m$line\033[0m"
            elif (( $(echo "$cpu_usage > 20" | bc -l) )); then
                # Medium CPU usage - Yellow
                echo -e "\033[1;33m$line\033[0m"
            else
                # Low CPU usage - Green
                echo -e "\033[1;32m$line\033[0m"
            fi
        done
        
        echo ""
        process_count=$(echo "$processes" | wc -l)
        if [ "$show_header" = "dashboard" ]; then
            echo -e "\033[1;36m📊 Statistics:\033[0m"
            echo -e "   Total processes: \033[1;34m$process_count\033[0m"
        else
            echo -e "\033[1;36m📊 Total processes running: \033[1;34m$process_count\033[0m"
        fi
        
        # Show total CPU usage with color
        total_cpu=$(echo "$processes" | awk '{sum += $3} END {printf "%.1f", sum}')
        if (( $(echo "$total_cpu > 100" | bc -l) )); then
            echo -e "   \033[1;31m⚠️  High CPU usage: ${total_cpu}%\033[0m"
        elif (( $(echo "$total_cpu > 50" | bc -l) )); then
            echo -e "   \033[1;33m⚠️  Moderate CPU usage: ${total_cpu}%\033[0m"
        else
            echo -e "   \033[1;32m✅ Low CPU usage: ${total_cpu}%\033[0m"
        fi
        
        # Show total Memory usage with color
        total_mem=$(echo "$processes" | awk '{sum += $4} END {printf "%.1f", sum}')
        if (( $(echo "$total_mem > 50" | bc -l) )); then
            echo -e "   \033[1;31m⚠️  High Memory usage: ${total_mem}%\033[0m"
        elif (( $(echo "$total_mem > 20" | bc -l) )); then
            echo -e "   \033[1;33m⚠️  Moderate Memory usage: ${total_mem}%\033[0m"
        else
            echo -e "   \033[1;32m✅ Low Memory usage: ${total_mem}%\033[0m"
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
        echo -e "\033[1;36m🔄 Auto-refreshing every 3 seconds...\033[0m"
        echo -e "\033[1;33mPress 'q' to return to menu\033[0m"
        echo ""
        
        # Use read with timeout and check for 'q' input
        if read -t 3 -r -p ""; then
            if [[ "$REPLY" =~ ^[qQ]$ ]]; then
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
    echo -e "\033[1;34m1.\033[0m Auto-Clean Logs: \033[1;33m$AUTO_CLEAN_LOGS\033[0m"
    echo -e "\033[1;34m2.\033[0m Clean Up Logs (delete large files)"
    echo -e "\033[1;34m3.\033[0m Return to Main Menu"
    echo ""
    echo "=========================================="
    echo -n "Please select an option [1-3]: "
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
                cleanup_logs
                echo "Press Enter to continue..."
                read
                ;;
            3)
                break
                ;;
            *)
                echo -e "\033[1;31mInvalid option! Please select 1-3.\033[0m"
                echo "Press Enter to continue..."
                read
                ;;
        esac
    done
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
    echo -e "\033[1;34m7.\033[0m Exit"
    echo ""
    echo -e "\033[1;34m0.\033[0m \033[1;31mStop All Nexus Processes\033[0m \033[1;33m(Force Kill)\033[0m"
    echo ""
    echo "=========================================="
    echo -n "Please select an option [0-7]: "
}

# Main program loop
main() {
    while true; do
        display_menu
        read choice
        echo ""
        
        case $choice in
            1)
                launch_nexus_processes "all"
                echo "Press Enter to continue..."
                read
                ;;
            2)
                launch_nexus_processes "half"
                echo "Press Enter to continue..."
                read
                ;;
            3)
                check_running_processes
                echo "Press Enter to continue..."
                read
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
                echo "Exiting Nexus Network Node Manager..."
                exit 0
                ;;
            0)
                stop_all_nexus_processes
                echo "Press Enter to continue..."
                read
                ;;
            *)
                echo -e "\033[1;31mInvalid option! Please select 0-7.\033[0m"
                echo "Press Enter to continue..."
                read
                ;;
        esac
    done
}

# Start the program
main
