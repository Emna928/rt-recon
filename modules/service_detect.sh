#!/bin/bash 
# DESC: Banner grab and service parsing on open ports

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
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

IFS='-' read -r START_PORT END_PORT <<< "$PORT_RANGE"
validate_target "$TARGET"
validate_port "$START_PORT" "$END_PORT"

########################service detect function#############################
REPORT_DIR=$(dirname "$OUTPUT_FILE")
LOG_FILE="$REPORT_DIR/scan.log"

service_detect (){
    local ip=$1
    local port=$2
    local output 
    local banner
    local result
        result="[OPEN] $ip:$port"
        output=$(colored_output "$result")
        output+=$'\n'" -> $port"
        banner=$(banner_grab "$ip" "$port")
        BANNER=$banner

        if [[ -n "$banner" ]]; then
            output+=$'\n'"[BANNER] $banner"$'\n'"$(banner_parse "$banner")"   
        else
             output+=$'\n'"[NO BANNER] $ip:$port port open but no data returned"  
        fi
            printf '%s\n' "$output" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT_FILE"
   
        if [[ -n "$banner" ]];then
           log "INFO" "Banner $ip:$port $banner"
        else
           log "INFO" "[NO BANNER] $ip:$port port open but no data returned"
        fi
} 

########################Reports initialization#############################
HTML_PATH=""
if [[ "$HTML_FILE" = true ]];then 
  HTML_PATH="$REPORT_DIR/report.html"
  html_init "$HTML_PATH"
fi

CSV_PATH=""
if [[ "$CSV_FILE" = true ]]; then 
  CSV_PATH="$REPORT_DIR/results.csv"
  csv_init "$CSV_PATH"
fi

MD_PATH=""
if [[ "$MD_FILE" = true ]];then 
   MD_PATH="$REPORT_DIR/report.md"
   md_init "$MD_PATH"
fi

################work for one host################
detect_host(){
   local host=$1
   local open_file="$REPORT_DIR/${host}_open_ports.txt"
   local ports=()
   local port
   local result
   local p

   if [[ ! -f "$open_file" ]];then 
   : > "$open_file"
      for port in $(seq "$START_PORT" "$END_PORT");do  
       result=$(check_port "$host" "$port")
        if [[ "$result" = *"OPEN"* ]];then
         echo "$port" >> "$open_file"
        fi
      done
    fi

mapfile -t ports < <(sort -n "$open_file")

if [[ ${#ports[@]} -eq 0 ]]; then 
  return 0
fi 

{
  { 
  echo "Rt-Recon Report "
  echo ""
  printf "Generated: $(date +"%Y-%m-%d %H:%M:%S") \n"
  echo ""
  printf "=============== HOST: %s ===============\n" "$host"
  } >> "$OUTPUT_FILE"
  for p in "${ports[@]}";do 
    service_detect "$host" "$p"
    if [[ -n "$CSV_PATH" ]];then 
      csv_row "$CSV_PATH" "$host" "$p" "OPEN" "$BANNER"
    fi  
    if [[ -n "$HTML_PATH" ]];then 
      html_row "$HTML_PATH" "$host" "$p" "OPEN" "$BANNER"
    fi
    if [[ -n "$MD_PATH" ]]; then 
     md_row "$MD_PATH" "$host" "$p" "OPEN" "$BANNER"
    fi
  done 
  printf "Total: %d port(s) found.\n" "${#ports[@]}"
} >> "$OUTPUT_FILE"
}

################loop over every host################
mapfile -t HOSTS < <(get_hosts "$TARGET")

for host in "${HOSTS[@]}"; do 
  if ! host_alive "$host" > /dev/null;then 
    continue
  fi 
  detect_host "$host"
done

log "INFO" "Summary written to $OUTPUT_FILE"
if [[ -n "$CSV_PATH" ]]; then 
  log "INFO" "CSV report written to $CSV_PATH"
fi

if [[ -n "$MD_PATH" ]]; then 
  log "INFO" "MD report written to $MD_PATH"
fi

if [[ -n "$HTML_PATH" ]];then 
  log "INFO" "HTML report written to $HTML_PATH"
fi




