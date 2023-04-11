#!/bin/bash

###########################################################
#
# Author: ctrlbyte
# Sending_Grounds Bash Scripting Challenge
#
# To stay in the spirit of ProLUG and Killercoda labs, 
# script serves as a psuedo-ansible "gather-facts" clone, 
# collecting system info from specified hosts. 
# Assumption is that "control node" running already has 
# setup passwordless SSH login to target nodes.
# 
# Requirements:
# - Catches signals
# - Has a help/usage statement
# - Uses named Exit codes
# - Has arg parsing
# - Posts it to this repo here
# - and the script of course works
# 
###########################################################

# Named exit codes
EXIT_SUCCESS=0
EXIT_INVALID_ARGS=1
EXIT_SIGNAL_RECEIVED=2

# Print help/usage
usage() {
cat<<EOF
Usage: $0 [options] <hostname1> <hostname2> ...
Type: Non-mutating (information only)
  Collects system info from specified hosts
Options:
  -q          Run quick scan (default)
  -f          Run full scan
  -h          Show help/usage
EOF
}

# Cleanup reports directory
cleanup() {
    echo "Cleaning up ${REPORT_DIR}"
    rm -rf ${REPORT_DIR}
}

# Handle signals
handle_signals() {
    echo "Recieved signal - Exiting gracefully..."
    cleanup
    exit $EXIT_SIGNAL_RECEIVED
}

# Create the output directory for reports
setup_dir() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    REPORT_DIR="/tmp/sysinfo-${timestamp}"
    mkdir ${REPORT_DIR}
    echo "Created directory: ${REPORT_DIR}"
}

# Collect system information from a host
collect_sys_info() {
    local hostname=$1
    local report="${REPORT_DIR}/${hostname}.log"
    echo "Gathering metrics from host '${hostname}' and writing to '${report}'"
    echo "++++++++++++++++++++++++++++++++++++++++" >> "$report"
    echo "++ Hostname: $hostname" >> "$report"
    echo "++ Date: $(date)" >> "$report"
    local ssh_output=$(ssh $hostname "
                            echo '++ Uptime:'; uptime;
                            echo '++ Memory:'; free -h;
                            echo '++ Disk Usage:'; df -h;
                            ")
    # Not quite production-ready, but an MVP for challenge?
    if [[ "$scan_mode" == "full" ]]; then
        ssh_output+=$(ssh $hostname "
                            echo -e '\n++ Kernel Version:'; uname -r; 
                            echo '++ IP Addresses:'; hostname -I
                            ")
    fi
    echo "$ssh_output" >> "$report"
    echo "++++++++++++++++++++++++++++++++++++++++" >> "$report"
}

# Main function serving as entrypoint
main() {
    # Trap signals
    trap 'handle_signals' SIGINT SIGTERM

    # Set default scan mode
    scan_mode="quick"

    # Parse arguments
    while getopts ":qfh" opt; do
        case "$opt" in
            q)
                scan_mode="quick"
                ;;
            f)
                scan_mode="full"
                ;;
            h)
                usage
                exit $EXIT_SUCCESS
                ;;
            *)
                usage
                exit $EXIT_INVALID_ARGS
                ;;
        esac
    done

    # Shift arguments to get list of hostnames
    shift "$((OPTIND-1))"

    # Check at least one hostname provided
    if [[ $# -lt 1 ]]; then
        echo "Error: At least one hostname must be provided."
        usage
        exit $EXIT_INVALID_ARGS
    fi

    # create directory for storing reports
    setup_dir

    # Loop through the list of hostnames and collect system information
    for hostname in "$@"; do
        collect_sys_info "$hostname"
    done

    echo "System information collected and saved to: ${REPORT_DIR}"

    exit $EXIT_SUCCESS
}

main $@
