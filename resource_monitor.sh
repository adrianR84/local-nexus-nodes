#!/bin/bash

# Resource Monitor Module for Nexus Network Node Manager
# This file contains all resource monitoring functions

# Function to get script resource usage
get_script_resources() {
    local script_pid=$$
    local script_info=$(ps -p $script_pid -o %cpu,%mem,rss,vsz --no-headers 2>/dev/null)
    if [ -n "$script_info" ]; then
        echo "$script_info"
    else
        echo "0.0 0.0 0 0"
    fi
}

# Function to get all nexus nodes resource usage
get_nodes_resources() {
    local nodes_info=$(ps aux | grep "nexus-network" | grep -v grep | awk '
    BEGIN {cpu=0; mem=0; rss=0; count=0}
    {
        cpu += $3
        mem += $4
        rss += $6
        count++
    }
    END {
        if (count > 0) {
            printf "%.1f %.1f %d %d", cpu, mem, rss, count
        } else {
            print "0.0 0.0 0 0"
        }
    }')
    echo "$nodes_info"
}

# Function to get system resources summary
get_system_resources() {
    local mem_info=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}')
    local cpu_info=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    echo "$cpu_info $mem_info"
}

# Function to format memory size
format_memory() {
    local kb=$1
    if [ $kb -ge 1048576 ]; then
        echo "$(echo "scale=1; $kb/1048576" | bc 2>/dev/null || echo $((kb/1048576)))GB"
    elif [ $kb -ge 1024 ]; then
        echo "$(echo "scale=1; $kb/1024" | bc 2>/dev/null || echo $((kb/1024)))MB"
    else
        echo "${kb}KB"
    fi
}

# Function to get brief resource summary for main menu
get_resource_summary() {
    local nodes_res=$(get_nodes_resources)
    read nodes_cpu nodes_mem nodes_rss node_count <<< "$nodes_res"
    
    if [ "$node_count" -gt 0 ]; then
        echo "CPU: ${nodes_cpu}% | RAM: $(format_memory $nodes_rss) | Nodes: $node_count"
    else
        echo "No active nodes"
    fi
}

# Function to show detailed system resources
show_system_resources() {
    clear
    echo -e "\033[1;34m🖥️  System Resources Monitor\033[0m"
    echo "=========================================="
    echo ""
    
    # Script resources
    echo -e "\033[1;36m📋 Script Resource Usage:\033[0m"
    local script_res=$(get_script_resources)
    read script_cpu script_mem script_rss script_vsz <<< "$script_res"
    echo -e "   CPU: \033[1;33m${script_cpu}%\033[0m | Memory: \033[1;33m${script_mem}%\033[0m"
    echo -e "   RSS: \033[1;33m$(format_memory $script_rss)\033[0m | VSZ: \033[1;33m$(format_memory $script_vsz)\033[0m"
    echo ""
    
    # Nexus nodes resources
    echo -e "\033[1;36m🔗 Nexus Nodes Resource Usage:\033[0m"
    local nodes_res=$(get_nodes_resources)
    read nodes_cpu nodes_mem nodes_rss node_count <<< "$nodes_res"
    if [ "$node_count" -gt 0 ]; then
        echo -e "   Active Nodes: \033[1;32m$node_count\033[0m"
        echo -e "   Total CPU: \033[1;33m${nodes_cpu}%\033[0m | Total Memory: \033[1;33m${nodes_mem}%\033[0m"
        echo -e "   Total RSS: \033[1;33m$(format_memory $nodes_rss)\033[0m"
        echo -e "   Avg per Node: CPU \033[1;33m$(echo "scale=1; $nodes_cpu/$node_count" | bc 2>/dev/null || echo "0")%\033[0m | Memory \033[1;33m$(echo "scale=1; $nodes_mem/$node_count" | bc 2>/dev/null || echo "0")%\033[0m"
    else
        echo -e "   \033[1;33mNo active nexus nodes found\033[0m"
    fi
    echo ""
    
    # System resources
    echo -e "\033[1;36m💻 System Resources:\033[0m"
    local sys_res=$(get_system_resources)
    read sys_cpu sys_mem <<< "$sys_res"
    echo -e "   System CPU: \033[1;33m${sys_cpu}%\033[0m | System Memory: \033[1;33m${sys_mem}\033[0m"
    echo ""
    
    # Total combined
    echo -e "\033[1;36m📊 Combined Usage:\033[0m"
    local total_cpu=$(echo "scale=1; $script_cpu + $nodes_cpu" | bc 2>/dev/null || echo "$script_cpu")
    local total_mem=$(echo "scale=1; $script_mem + $nodes_mem" | bc 2>/dev/null || echo "$script_mem")
    local total_rss=$(($script_rss + $nodes_rss))
    echo -e "   Total CPU: \033[1;31m${total_cpu}%\033[0m | Total Memory: \033[1;31m${total_mem}%\033[0m"
    echo -e "   Total RSS: \033[1;31m$(format_memory $total_rss)\033[0m"
    echo ""
    
    echo -e "\033[1;36m💡 Tip: Monitor these values to ensure optimal system performance.\033[0m"
    echo ""
    echo -e "\033[1;36m🔄 Auto-refreshing every 5 seconds...\033[0m"
    echo -e "\033[1;33mPress 'q' or ESC to return to menu\033[0m"
    echo ""
    
    # Auto-refresh loop
    while true; do
        sleep 5
        # Check for user input
        if read -t 0.1 -n 1 -s input 2>/dev/null; then
            if [[ "$input" == "q" ]] || [[ "$input" == $'\e' ]]; then
                break
            fi
        fi
        # Refresh the display
        show_system_resources
        return
    done
}
