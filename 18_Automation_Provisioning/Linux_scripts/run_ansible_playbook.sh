#!/bin/bash
#set -x
# Define variables
user_home="/home/ubuntu"
WORKING_DIR="${user_home}/01_lab/lab/01_tools/01_netapp_playbook/base_ansible"
LOG_DIR="${WORKING_DIR}/log"



# Help function
function show_help() {
    echo "Usage: $0 -p PLAYBOOK_NAME -v PLAYBOOK_VAR_NAME"
    echo ""
    echo "Options:"
    echo "  -p PLAYBOOK_NAME      Name of the Ansible playbook to run"
    echo "  -v PLAYBOOK_VAR_NAME  Name of the variables file to use"
    echo "  -h                    Show this help message"
}

# Parse input arguments
while getopts ":p:v:h" opt; do
    case ${opt} in
        p )
            PLAYBOOK_NAME=$OPTARG
            ;;
        v )
            PLAYBOOK_VAR_NAME=$OPTARG
            ;;
        h )
            show_help
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            show_help
            exit 1
            ;;
        : )
            echo "Invalid option: -$OPTARG requires an argument" 1>&2
            show_help
            exit 1
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$PLAYBOOK_NAME" ] || [ -z "$PLAYBOOK_VAR_NAME" ]; then
    echo "Error: Both PLAYBOOK_NAME and PLAYBOOK_VAR_NAME are required."
    show_help
    exit 1
fi


# Define variables
PLAYBOOK_PATH="${WORKING_DIR}/${PLAYBOOK_NAME}"
#LOG_FILE="$LOG_DIR/${PLAYBOOK_NAME}_$(date +'%Y%m%d_%H%M%S').log"
LOG_FILE="$LOG_DIR/${PLAYBOOK_NAME}_$(date +'%Y%m%d').log"

# Ensure the log directory exists
mkdir -p $LOG_DIR

# Run the Ansible playbook and append the output to the log file
{
    echo "===== $(date +'%Y-%m-%d %H:%M:%S') ====="
    ansible-playbook $PLAYBOOK_PATH -e "vars_file=${WORKING_DIR}/${PLAYBOOK_VAR_NAME}"
    echo "========================================"
} >> $LOG_FILE 2>&1


