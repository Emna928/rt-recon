#!/bin/bash 
# DESC: Discover live hosts in an IP or CIDR range 
set -euo pipefail


SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." &>/dev/null && pwd )


source "$ROOT_DIR/config.conf"
source "$ROOT_DIR/lib/args_validation.sh"
source "$ROOT_DIR/lib/network.sh"
source "$ROOT_DIR/lib/output.sh"
source "$ROOT_DIR/lib/logging.sh" 


################Parsing flags###################
module_parse_args "$@"
if [[ -z $TARGET ]] ; then
   echo "Error: Option -t is required"
   usage
   exit 1
fi


REPORT_DIR=$(dirname "$OUTPUT_FILE")
LOG_FILE="$REPORT_DIR/scan.log"

################startup####################
print_banner 
log "INFO" "Rt-Recon_Framework-nulltack TOOL is starting"

if is_cidr "$TARGET"; then 
  log "INFO" "CIDR detected! expanding $TARGET"
  mapfile -t HOSTS < <(expand_cidr "$TARGET")
else 
  validate_ip "$TARGET"
  HOSTS=("$TARGET")
fi 

################Build list of hosts to check####################
LIVE_HOSTS=()
DOWN_HOSTS=()
for host in "${HOSTS[@]}"; do 
   if host_alive "$host"; then 
      log "INFO" "$host is UP"
      LIVE_HOSTS+=("$host")
   else 
      log "ERROR" "$host is DOWN"
      DOWN_HOSTS+=("$host")
   fi
done

################Host discovery summury####################

if is_cidr "$TARGET";then 
: > "$REPORT_DIR/live_hosts.txt"
   for h in "${LIVE_HOSTS[@]}"; do
        echo "$h" >> "$REPORT_DIR/live_hosts.txt"
   done
fi 

if [[ ${#LIVE_HOSTS[@]} -eq 0 ]]; then 
   log "ERROR" "No live host found - exiting"
   exit 1
fi


