#! /bin/bash

################error handling####################
set -euo pipefail 

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
################source librairies####################
source $SCRIPT_DIR/config.conf
source $SCRIPT_DIR/lib/drop_in_module.sh
source $SCRIPT_DIR/lib/args_validation.sh
source $SCRIPT_DIR/lib/network.sh
source $SCRIPT_DIR/lib/output.sh
source $SCRIPT_DIR/lib/logging.sh


export TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
################reports location####################
if [[ -n "${RT_RECON_REPORTS:-}" ]];then 
  REPORTS_BASE="$RT_RECON_REPORTS"
elif [[ -w "$SCRIPT_DIR" ]]; then
  REPORTS_BASE="$SCRIPT_DIR/reports"
else
  REPORTS_BASE="$HOME/.local/share/rt-recon/reports"
fi

################help manual####################
show_help() {
cat << 'EOF'

 ____  _     ____                        _____                                            _    
|  _ \| |_  |  _ \ ___  ___ ___  _ __   |  ___| __ __ _ _ __ ___   _____      _____  _ __| | __
| |_) | __| | |_) / _ \/ __/ _ \| '_ \  | |_ | '__/ _` | '_ ` _ \ / _ \ \ /\ / / _ \| '__| |/ /
|  _ <| |_  |  _ <  __/ (_| (_) | | | | |  _|| | | (_| | | | | | |  __/\ V  V / (_) | |  |   < 
|_| \_\\__| |_| \_\___|\___\___/|_| |_| |_|  |_|  \__,_|_| |_| |_|\___| \_/\_/ \___/|_|  |_|\_\
                                                                                               
                                                                         
  RT-Recon_Framework -- Modular reconnaissance toolkit 
  For authorized security testing and internal red team engagement only 

USAGE:
  ./main.sh --module <module_name> -t <target> -p <start_end> [-c <threads>] [-o <output_file>] [-s] [-H] [-m] [-l] [-v]

MODULES:
EOF
print_modules_help
cat << 'EOF'
  
REQUIRED OPTIONS:
  --module <name>                    Module to run (see MODULES above)
  -t <target>                        Target IP or CIDR range (e.g. 192.168.1.10 or 192.168.1.0/24)

OPTIONAL OPTIONS:
  -h, --help          Show this help menu and exit
  -p <start-end>      Port range to scan (required for port_scan/service_detect;optional for host_discovery e.g. 1-1000)
  -c <n>              Max concurrent jobs / semaphore limit (default: 20)
  -o <file>           Output file name (default: report.txt)
  -v                  Show verbose output, including closed/timed-out ports
  -s                  Write result to CSV file
  -H                  Write a colored HTML report
  -m                  Write a markdown report
  -l                  Display the content of scan.log if enabled

EXAMPLES:
  # Basic port scan on a single host
  ./main.sh --module port_scan -t 192.168.1.10 -p 1-1000

  # Host discovery across a subnet
  ./main.sh --module host_discovery -t 192.168.1.0/24

  # Port scan with custom concurrency
  ./main.sh --module port_scan -t 10.0.0.5 -p 1-65535 -c 50 -s -v

   # Full recon with TXT, HTML, CSV, markdown report and logging
  ./main.sh --module all -t 10.0.0.5 -p 1-65535 -c 50 -o report.txt -s -H -m -l -v

EXIT CODES:
  0     Success
  1     Invalid arguments or validation failure
  130   Interrupted by user (Ctrl+C)
    
EOF
}

################parse CLI flags ###########################
OTHER_ARGS=()
while [[ $# -gt 0 ]]; do 
   case "$1" in 
     --module) 
        if [[ $# -lt 2 ]]; then 
           echo "Error - module requires a value"
           usage
        fi
        MODULE="$2"; shift 2 ;;
     -h|--help) show_help; exit 0 ;;
     *) OTHER_ARGS+=("$1")
        shift;;
   esac
done
################validate module#################
if [[ -z $MODULE ]]; then 
   usage
fi 

if [[ "$MODULE" != "all" ]] && ! module_exists "$MODULE"; then
   echo "Error: unknow module '$MODULE'. Available: $(list_modules | tr '\n' ' ')all"
   usage
fi

################parse_args#################
module_parse_args "${OTHER_ARGS[@]}"

################required options#################
if [[ -z "$TARGET" ]] ; then
  echo "Error: Options -t is required"
  usage 
fi

#_p is required for every module except host_discovery module #################
if [[ "$MODULE" != "host_discovery" ]] && [[ -z "$PORT_RANGE" ]]; then
echo "Error: Options -p is required for this '$MODULE'"
  usage
fi 

###################validate target #######################
validate_target "$TARGET"

################validate port only if one is given########
if [[ -n "$PORT_RANGE" ]]; then 
    IFS='-' read -r START_PORT END_PORT <<< "$PORT_RANGE"
    validate_port "$START_PORT" "$END_PORT"
fi 

################Timestamped report output #################

TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
SESSION_DIR="$REPORTS_BASE/$TIMESTAMP"
REPORT_DIR="$SESSION_DIR/scan_result"
mkdir -p "$REPORT_DIR"

OUTPUT_FILE="$REPORT_DIR/$(basename "${OUTPUT_FILE:-report.txt}")"
LOG_FILE="$REPORT_DIR/scan.log"


################Module error recovery ####################
run_safely(){
    local module=$1
    shift

    if bash "$SCRIPT_DIR/modules/${module}.sh" "$@"; then
      if [[ "$MODULE" = "all" ]]; then 
        log "INFO" "$module completed successfully"
      fi
       return 0
    else 
      if [[ "$MODULE" = "all" ]]; then 
        log "ERROR" "$module failed"
      fi
       return 1
    fi 
}
################Run chain host_discovery, scan_port and service_detect ####################
run_chain (){
  local extra=(-c "$MAX_THREADS")
  local hosts=()

  if [[ "$VERBOSE" = true ]]; then
    extra+=(-v)
  fi

  if [[ "$CSV_FILE" = true ]]; then
    extra+=(-s)
  fi

  if [[ "$HTML_FILE" = true ]]; then 
    extra+=(-H)
  fi

  if [[ "$MD_FILE" = true ]]; then 
     extra+=(-m)
  fi 
  
  if [[ "$LOG_ENABLED" = true ]];then
     extra+=(-l)
  fi


  if ! run_safely host_discovery -t "$TARGET" -o "$OUTPUT_FILE" "${extra[@]}";then
    log "ERROR" "no host discovery, nothing to scan"
    return 1;
  fi

  if is_cidr "$TARGET";then 
    mapfile -t hosts < "$REPORT_DIR/live_hosts.txt"
  else
    hosts=("$TARGET")
  fi

  for host in "${hosts[@]}";do
     if ! run_safely port_scan -t "$host" -p "$PORT_RANGE" -o "$OUTPUT_FILE" "${extra[@]}"; then
      log "WARN" "skipping $host";
      continue
     fi 
     if ! run_safely service_detect -t "$host" -p "$PORT_RANGE" -o "$OUTPUT_FILE" "${extra[@]}";then 
      log "WARN" "service_detect failed on $host"
     fi
  done 
}

################call run safely  ####################
args=(-t "$TARGET" -c "$MAX_THREADS" -o "$OUTPUT_FILE")
if [[ -n $PORT_RANGE ]]; then 
  args+=(-p "$PORT_RANGE" )
fi 
if [[ $VERBOSE = true ]]; then 
  args+=(-v)
fi
if [[ $CSV_FILE = true ]];then 
  args+=(-s)
fi
if [[ $HTML_FILE = true ]];then 
  args+=(-H)
fi
if [[ $MD_FILE = true ]]; then 
  args+=(-m)
fi
if [[ "$LOG_ENABLED" = true ]]; then 
  args+=(-l)
fi

if [[ "$MODULE" = "all" ]]; then 
   run_chain || true
else
   run_safely "$MODULE" "${args[@]}"||true
fi

if [[ -f "$REPORT_DIR/report.html" ]];then 
  echo "</table></body></html>" >> "$REPORT_DIR/report.html"
fi 

################tool ending ####################
log "INFO" "TOOL is ending"