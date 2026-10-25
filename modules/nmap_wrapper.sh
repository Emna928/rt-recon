#!/bin/bash
# DESC: Wrapper around nmap, if installed

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)

source $ROOT_DIR/config.conf
source $ROOT_DIR/lib/args_validation.sh 
source $ROOT_DIR/lib/logging.sh
source "$ROOT_DIR/lib/network.sh"
source "$ROOT_DIR/lib/output.sh"

################Parsing flags###################
module_parse_args "$@"

if [[ -z "$TARGET" ]] || [[ -z "$PORT_RANGE" ]]; then
    echo "Error: Options -t and -p are required"
    usage
fi

################validate input###################
validate_target "$TARGET"
IFS='-' read -r START_PORT END_PORT <<< "$PORT_RANGE"
validate_port "$START_PORT" "$END_PORT"

REPORT_DIR=$(dirname "$OUTPUT_FILE")
LOG_FILE="$REPORT_DIR/scan.log"
NMAP_TXT="$REPORT_DIR/nmap_report.txt"
NMAP_XML="$REPORT_DIR/nmap_results.xml"


if ! command -v nmap &>/dev/null ; then 
   log "ERROR" "nmap is not installed on this system. Install it with: sudo apt install nmap"
   exit 1
fi 

################run nmap###################
log "INFO" "Running nmap on $TARGET ports $PORT_RANGE"
if ! nmap -sT -sV -T3 --open -p "$PORT_RANGE" "$TARGET" -oN "$NMAP_TXT" -oX "$NMAP_XML"; then
    log "ERROR" "nmap failed"
    exit 1
fi

log "INFO" "nmap report written to $NMAP_TXT"
log "INFO" "nmap XML written to $NMAP_XML"


