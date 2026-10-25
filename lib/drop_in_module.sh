#!/bin/bash 

################plugin / drop-in module discovery####################
list_modules(){
    local file
    for file in "$SCRIPT_DIR"/modules/*.sh; do
        [[ -f "$file" ]] || continue
        basename "$file" .sh
    done
}

module_exists(){
    local name=$1
    [[ "$name" =~ ^[a-zA-Z0-9_]+$ ]] || return 1
    [[ -f "$SCRIPT_DIR/modules/$name.sh" ]]
}

module_description(){
    local name=$1
    local desc
    desc=$(grep -m1 '^# DESC:' "$SCRIPT_DIR/modules/$name.sh" | sed 's/^# DESC: *//')
    echo "${desc:-NO description}"
}

print_modules_help(){
    local name
    while read -r name;do 
       printf " %-18s %s\n" "$name" "$(module_description "$name")" 
    done < <(list_modules)
    printf " %-18s %s\n" "all" "Run host_discovery, port_scan and service_detect in sequence"
}