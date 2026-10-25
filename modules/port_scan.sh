#!/bin/bash 
# DESC: Scan ports with configurable concurrency
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd)

source "$ROOT_DIR/config.conf"
source "$ROOT_DIR/lib/args_validation.sh"
source "$ROOT_DIR/lib/network.sh"
source "$ROOT_DIR/lib/output.sh"
source "$ROOT_DIR/lib/logging.sh"

################Parsing flags###################
module_parse_args "$@"
if [[ -z "$TARGET" ]] || [[ -z "$PORT_RANGE" ]]; then
    echo "Error: Options -t and -p are required"
    usage
fi

################validate ip and port #####################
validate_target "$TARGET"
IFS='-' read -r START_PORT END_PORT <<< "$PORT_RANGE"
validate_port "$START_PORT" "$END_PORT"

################Cleanup function#####################
REPORT_DIR=$(dirname "$OUTPUT_FILE")
LOG_FILE="$REPORT_DIR/scan.log"


#################Signal log function#################
sig_log (){  
    log "WARN" "\n[!] Scan interrupted. Exiting."
}

trap 'sig_log; exit 130' INT;

################port scan function####################
log "INFO" "Scan checking $TARGET $PORT_RANGE"

port_scan(){
    local ip=$1
    local port=$2 
    local result
    result=$(check_port "$ip" "$port")

    if [[ "$result" = *"OPEN"* ]]; then 
        echo "$port" >> "$OPEN_PORTS_FILE"
        colored_output "$result"
    elif [[ "$result" = *"TIMEOUT"* ]] || [[ "$VERBOSE" = "true" ]]; then
        colored_output "$result" 
    fi 

    log_result "$result"
} 

################paralell scan (max 20 concurrents)####################
mapfile -t HOSTS < <(get_hosts "$TARGET")

for host in "${HOSTS[@]}";do 
    if ! host_alive "$host" > /dev/null; then 
      continue 
    fi
    log "INFO" "Scanning $host ports $PORT_RANGE"
    OPEN_PORTS_FILE="$REPORT_DIR/${host}_open_ports.txt"
    : > "$OPEN_PORTS_FILE"

    job_count=0
    for port in $(seq "$START_PORT" "$END_PORT"); do
       port_scan "$host" "$port" &
       job_count=$((job_count +1))
        if [[ $job_count -ge $MAX_THREADS ]]; then 
           wait
           job_count=0
        fi
    done
    wait
done

