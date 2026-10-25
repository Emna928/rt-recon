#!/bin/bash

################Log function####################
log (){
    local level=$1
    local message=$2
    local entry
    
    entry="$(date +"%Y-%m-%d %H:%M:%S") $level $message"

  if [[ "${LOG_ENABLED:-false}" = true ]] && [[ -n "${LOG_FILE:-}" ]]; then
     echo "$entry" | tee -a "${LOG_FILE:-scan.log}" >&2
  fi

}

################Log result function####################
log_result(){
    local result=$1;
    
    if [[ "$result" = *"OPEN"* ]]; then 
       log "INFO" "$result"
    elif [[ "$result" = *"TIMEOUT"* ]]; then 
       log "WARN" "$result"
    else 
       log "ERROR" "$result"
    fi
}







