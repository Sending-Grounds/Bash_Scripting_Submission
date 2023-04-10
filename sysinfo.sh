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
    echo "Usage: $0 [options] <hostname1> <hostname2> ..."
    echo "  Collects system info from specified hosts"
    echo "Options:"
    echo "  -q          Run quick scan (default)"
    echo "  -f          Run full scan"
    echo "  -h          Show help/usage"
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
    echo -e "Hostname:\n $hostname" >> "$report"
    echo -e "Date:\n $(date)" >> "$report"
    echo -e "Uptime:\n $(ssh $hostname uptime)" >> "$report"
    echo -e "Memory:\n $(ssh $hostname free -h)" >> "$report"
    echo -e "Disk Usage:\n $(ssh $hostname df -h)" >> "$report"
    # Not quite production-ready, but an MVP for challenge?
    if [[ "$scan_mode" == "full" ]]; then
        echo "Kernel Version:\n $(ssh $hostname uname -r)" >> "$report"
        echo "IP Addresses:\n $(ssh $hostname hostname -I)" >> "$report"
    fi
    echo "++++++++++++++++++++++++++++++++++++++++" >> "$report"
}

# create directory for storing reports
setup_dir

# Loop through the list of hostnames and collect system information
for hostname in "$@"; do
    collect_sys_info "$hostname"
done

# Janky idea of unit tests
# Send CTRL^C during this period to ensure reports directory gets cleaned
sleep 10

# Print completion message
echo "System information collected and saved to: ${REPORT_DIR}"

exit $EXIT_SUCCESS
