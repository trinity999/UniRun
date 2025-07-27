#!/bin/bash

#########################################################################
# Universal Command Runner for Chaos Database
# 
# DESCRIPTION:
#   Execute commands across multiple client folders in bug bounty database.
#   Automatically discovers client folders containing 'assets.txt' or 
#   'roots.txt' files and runs specified reconnaissance commands.
#
# AUTHOR: Created for Chaos Database Management
# VERSION: 2.0
#
# USAGE:
#   ./uni_run.sh [OPTIONS] "COMMAND"
#
# EXAMPLES:
#   ./uni_run.sh "dir"                                    # Simple test
#   ./uni_run.sh -v -c "subfinder -dL roots.txt -o sub.txt" # Verbose with continue-on-error
#   ./uni_run.sh -d "httpx -l assets.txt -o httpx.txt"    # Dry run
#   ./uni_run.sh -l scan.log "nuclei -l assets.txt"      # With logging
#   ./uni_run.sh -p /custom/path -f "BC,H1" "command"     # Custom path and folders
#
# OPTIONS:
#   -h, --help           Show this help message
#   -d, --dry-run        Show what would be executed without running
#   -c, --continue       Continue processing even if a command fails
#   -v, --verbose        Enable detailed logging output
#   -l, --log FILE       Write output to log file (in addition to console)
#   -p, --path PATH      Base directory path (default: current directory)
#   -f, --folders LIST   Comma-separated list of folders (default: BC,H1,IG,MS,SH)
#
# PREREQUISITES:
#   - Client folders must contain 'assets.txt' or 'roots.txt' files
#   - Specified command/tool must be available in PATH
#   - Bash 4.0+ for associative arrays
#
# FEATURES:
#   - Automatic client folder discovery
#   - Progress tracking with percentage completion
#   - Colored console output for better readability
#   - Comprehensive error handling and reporting
#   - Dry run capability for testing
#   - Optional logging to file
#   - Execution statistics and success rate calculation
#
# EXIT CODES:
#   0: All commands executed successfully
#   1: One or more commands failed or invalid usage
#   2: Prerequisites not met (missing folders, files, etc.)
#
#########################################################################

# Default values
BASE_PATH="C:/Users/abhij/bb"
FOLDERS=("BC" "H1" "IG" "MS" "SH")
DRY_RUN=false
CONTINUE_ON_ERROR=false
VERBOSE=false
LOG_FILE=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Function to write log messages
write_log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_message="[$timestamp] [$level] $message"
    
    # Color coding for console output
    case $level in
        "ERROR")
            echo -e "${RED}$log_message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}$log_message${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}$log_message${NC}"
            ;;
        "INFO")
            echo -e "${WHITE}$log_message${NC}"
            ;;
        *)
            echo -e "${GRAY}$log_message${NC}"
            ;;
    esac
    
    # Write to log file if specified
    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_message" >> "$LOG_FILE"
    fi
}

# Function to show usage
show_usage() {
    echo "Universal Command Runner for Chaos Database"
    echo ""
    echo "Usage: $0 [OPTIONS] \"COMMAND\""
    echo ""
    echo "Options:"
    echo "  -d, --dry-run           Show what would be executed without running"
    echo "  -c, --continue-on-error Continue execution even if some commands fail"
    echo "  -v, --verbose           Show detailed output"
    echo "  -l, --log-file FILE     Write logs to specified file"
    echo "  -p, --path PATH         Base path (default: $BASE_PATH)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 \"httpx -l assets.txt -o httpx.txt\""
    echo "  $0 -c -v \"subfinder -dL roots.txt -o subfinder.txt\""
    echo "  $0 --dry-run \"nmap -iL assets.txt -oN nmap.txt\""
}

# Function to validate prerequisites
test_prerequisites() {
    write_log "Validating prerequisites..." "INFO"
    
    # Check if base path exists
    if [[ ! -d "$BASE_PATH" ]]; then
        write_log "Base path does not exist: $BASE_PATH" "ERROR"
        return 1
    fi
    
    # Check if any folders exist
    local found_folders=0
    for folder in "${FOLDERS[@]}"; do
        local folder_path="$BASE_PATH/$folder"
        if [[ -d "$folder_path" ]]; then
            ((found_folders++))
        fi
    done
    
    if [[ $found_folders -eq 0 ]]; then
        write_log "No valid folders found in: $BASE_PATH" "ERROR"
        return 1
    fi
    
    write_log "Found $found_folders valid folders" "SUCCESS"
    return 0
}

# Function to count total client folders
get_total_client_folders() {
    local total=0
    for folder in "${FOLDERS[@]}"; do
        local folder_path="$BASE_PATH/$folder"
        if [[ -d "$folder_path" ]]; then
            local count=$(find "$folder_path" -maxdepth 1 -type d ! -path "$folder_path" | wc -l)
            ((total += count))
        fi
    done
    echo $total
}

# Function to execute command in a folder
execute_command_in_folder() {
    local folder_path="$1"
    local folder_name="$2"
    local command="$3"
    
    # Change to the target directory
    pushd "$folder_path" > /dev/null 2>&1
    
    if [[ $? -ne 0 ]]; then
        write_log "❌ FAILED: Cannot access $folder_name" "ERROR"
        return 1
    fi
    
    if [[ "$VERBOSE" == true ]]; then
        write_log "Executing in $folder_name: $command" "INFO"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        write_log "DRY RUN - Would execute: $command" "WARN"
        popd > /dev/null 2>&1
        return 0
    fi
    
    # Execute the command
    local output
    local exit_code
    
    if [[ "$VERBOSE" == true ]]; then
        eval "$command"
        exit_code=$?
    else
        output=$(eval "$command" 2>&1)
        exit_code=$?
    fi
    
    # Return to original directory
    popd > /dev/null 2>&1
    
    if [[ $exit_code -eq 0 ]]; then
        write_log "✅ SUCCESS: $folder_name" "SUCCESS"
        if [[ "$VERBOSE" == true && -n "$output" ]]; then
            write_log "Output: $output" "INFO"
        fi
        return 0
    else
        write_log "❌ FAILED: $folder_name (Exit code: $exit_code)" "ERROR"
        if [[ -n "$output" ]]; then
            write_log "Error output: $output" "ERROR"
        fi
        return 1
    fi
}

# Main execution function
main() {
    write_log "=== UNIVERSAL COMMAND RUNNER ===" "INFO"
    write_log "Base Path: $BASE_PATH" "INFO"
    write_log "Command: $COMMAND" "INFO"
    write_log "Folders: ${FOLDERS[*]}" "INFO"
    
    if [[ "$DRY_RUN" == true ]]; then
        write_log "DRY RUN MODE - No commands will be executed" "WARN"
    fi
    
    if [[ -n "$LOG_FILE" ]]; then
        write_log "Logging to file: $LOG_FILE" "INFO"
        # Create log file directory if it doesn't exist
        mkdir -p "$(dirname "$LOG_FILE")"
    fi
    
    write_log "" "INFO"
    
    # Validate prerequisites
    if ! test_prerequisites; then
        write_log "Prerequisites validation failed. Exiting." "ERROR"
        exit 1
    fi
    
    # Get total count for progress tracking
    local total_folders
    total_folders=$(get_total_client_folders)
    write_log "Total client folders to process: $total_folders" "INFO"
    write_log "" "INFO"
    
    # Execution statistics
    local processed=0
    local successful=0
    local failed=0
    local skipped=0
    
    # Process each main folder
    for folder in "${FOLDERS[@]}"; do
        local folder_path="$BASE_PATH/$folder"
        
        if [[ ! -d "$folder_path" ]]; then
            write_log "Skipping non-existent folder: $folder" "WARN"
            continue
        fi
        
        write_log "Processing folder: $folder" "INFO"
        
        # Check if folder has client subdirectories
        local client_count=$(find "$folder_path" -maxdepth 1 -type d ! -path "$folder_path" | wc -l)
        
        if [[ $client_count -eq 0 ]]; then
            write_log "No client folders found in: $folder" "WARN"
            continue
        fi
        
        # Process each client folder
        for client_path in "$folder_path"/*/; do
            [[ ! -d "$client_path" ]] && continue
            
            local client_name=$(basename "$client_path")
            ((processed++))
            
            local progress_percent
            if [[ $total_folders -gt 0 ]]; then
                progress_percent=$(echo "scale=1; ($processed * 100) / $total_folders" | bc -l 2>/dev/null || echo "0")
            else
                progress_percent="0"
            fi
            
            # Check if folder has the required structure
            local has_assets=false
            local has_roots=false
            
            [[ -f "${client_path}assets.txt" ]] && has_assets=true
            [[ -f "${client_path}roots.txt" ]] && has_roots=true
            
            if [[ "$has_assets" == false && "$has_roots" == false ]]; then
                write_log "⚠️ SKIP: $folder/$client_name - Missing assets.txt and roots.txt" "WARN"
                ((skipped++))
                continue
            fi
            
            write_log "[$processed/$total_folders] (${progress_percent}%) Processing: $folder/$client_name" "INFO"
            
            # Execute command in the client folder
            if execute_command_in_folder "$client_path" "$folder/$client_name" "$COMMAND"; then
                ((successful++))
            else
                ((failed++))
                
                # Check if we should continue on error
                if [[ "$CONTINUE_ON_ERROR" != true ]]; then
                    write_log "Stopping execution due to error. Use -c or --continue-on-error to continue despite failures." "ERROR"
                    break 2
                fi
            fi
        done
        
        write_log "" "INFO"
    done
    
    # Final summary
    write_log "=== EXECUTION SUMMARY ===" "INFO"
    write_log "Total folders: $total_folders" "INFO"
    write_log "Processed: $processed" "INFO"
    write_log "Successful: $successful" "SUCCESS"
    
    if [[ $failed -gt 0 ]]; then
        write_log "Failed: $failed" "ERROR"
    else
        write_log "Failed: $failed" "INFO"
    fi
    
    write_log "Skipped: $skipped" "WARN"
    
    local success_rate
    if [[ $processed -gt 0 ]]; then
        success_rate=$(echo "scale=1; ($successful * 100) / $processed" | bc -l 2>/dev/null || echo "0")
    else
        success_rate="0"
    fi
    
    if [[ $(echo "$success_rate == 100" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        write_log "Success rate: ${success_rate}%" "SUCCESS"
    else
        write_log "Success rate: ${success_rate}%" "WARN"
    fi
    
    write_log "=== EXECUTION COMPLETE ===" "INFO"
    
    # Exit with appropriate code
    if [[ $failed -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -c|--continue-on-error)
            CONTINUE_ON_ERROR=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -l|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        -p|--path)
            BASE_PATH="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            else
                echo "Multiple commands specified. Only one command is allowed." >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate command parameter
if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}ERROR: Command parameter is required!${NC}" >&2
    echo -e "${YELLOW}Usage: $0 \"httpx -l assets.txt -o httpx.txt\"${NC}" >&2
    echo -e "${YELLOW}       $0 -c -v \"subfinder -dL roots.txt -o subfinder.txt\"${NC}" >&2
    exit 1
fi

# Start execution
main
