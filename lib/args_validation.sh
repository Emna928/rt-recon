#!/bin/bash 

################target validation function ####################
validate_ip(){
     local ip=$1

    if ! [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then 
           echo "[Error] invalid IP address: $ip "
           exit 1
    fi 

    while IFS='.' read  -r octet1 octet2 octet3 octet4; do
        for octet in "$octet1" "$octet2" "$octet3" "$octet4"; do
            if [[ ${#octet} -gt 1 ]] && [[ ${octet:0:1} -eq 0 ]] || [[ $octet -gt 255 ]] ; then 
                echo "[ERROR] Invalid ip address $ip"
                exit 1
            fi
        done
    done <<< "$ip"
}

################port validation function ####################
validate_port (){
    local START_PORT=$1
    local END_PORT=$2

    if ! [[ $START_PORT =~ ^[0-9]+$ ]] || ! [[ $END_PORT =~ ^[0-9]+$ ]] || [[ $START_PORT -gt $END_PORT ]]; then 
       echo "[Error] invalid port: ports must numbers"
       exit 1
    elif [[ $START_PORT -lt 1 ]] || [[ $END_PORT -gt 65535 ]];then 
       echo "[Error]: invalid port range, port range [1-65535]" 
       exit 1
    fi 
}

usage (){
    echo "USAGE:"
    echo "./main.sh --module <module_name> -t <target> -p <start_end> [-c <threads>] [-o <output_file>] [-s] [-H] [-m] [-l] [-v]"
    exit 1
}

################validate target####################
validate_target (){
    local t=$1
    if is_cidr "$t"; then 
    validate_ip "${t%/*}"
    local prefix=${t#*/}
        if ! [[ $prefix =~ ^[0-9]+$ ]] || [[ $prefix -lt 8 ]] || [[ $prefix -gt 32 ]];then 
          echo "[Error] CIDR prefix must be between 8 and 32" >&2
          exit 1
        fi 
    else 
    validate_ip "$t"
    fi
}

################parse arguments####################
module_parse_args(){
    while getopts ":t:p:c:o:sHmlv" opt; do 
    case $opt in
    t) 
       TARGET=$OPTARG;;
    p) 
       PORT_RANGE=$OPTARG;;
    c)
       MAX_THREADS=$OPTARG;;
    o) 
       OUTPUT_FILE=$OPTARG;;
    s) 
       CSV_FILE=true;;
    H)
       HTML_FILE=true;;
    m)
       MD_FILE=true;;
    l)
       LOG_ENABLED=true;;
    v) 
       VERBOSE=true;;
    :)
        echo "Error: Option -$OPTARG requires an argument"
        usage
        exit 1;;
    \?)
        echo "Unknown flag: -$OPTARG"
        usage
        exit 1;;
    esac
done
    shift $((OPTIND - 1))
}


