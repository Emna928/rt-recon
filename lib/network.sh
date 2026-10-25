#!/bin/bash

################Host alive function####################
host_alive (){
  local ip=$1

  if  ping -c 1 -W 1 "$ip" &>/dev/null ; then 
    echo "[UP] $ip is reachable"
  else
    echo "[DOWN] $ip not responding" &>/dev/null
    return 1
  fi
}

################Check port function####################
check_port () {
local ip=$1
local port=$2
local status=0

timeout 2 bash -c "echo > /dev/tcp/$ip/$port" 2>/dev/null || status=$?

  if [[ $status -eq 0 ]]; then
    echo "[OPEN] $1:$2" 
  elif [[ $status -eq 124 ]]; then 
    echo "[TIMEOUT] $1:$2 — moving on."
  else
    echo "[CLOSED] $1:$2" 
  fi 
}

################Banner grab function####################
banner_grab (){
   local ip=$1;
   local port=$2;
  echo "" | nc -w 2 "$ip" "$port" 2>/dev/null | head -1
}

################Banner parse function####################
banner_parse (){
  local banner=$1;
  
  if [[ -z "$banner" ]];then
    printf "BANNER is empty"
    exit 1
  else
    echo "$banner" | cut -d '-' -f1 | awk '{printf "Protocol: "$0}'
    echo "$banner" | awk -F '-' '{printf "\nVersion: "$2"\n"}'
    echo "${banner%% *}" |awk -F '-' '{printf "Software: "$3"\n"}'
  fi
}

################CIDR detection###################
is_cidr() {
  local t=$1
   if [[ $t = */* ]]; then 
      return 0
   else 
      return 1
   fi 
}

expand_cidr(){
   local ip="${1%/*}"
   local prefix="${1#*/}"
   IFS='.' read -r octet1 octet2 octet3 octet4 <<<"$ip"
   local ip_int=$(( (octet1<<24)+(octet2<<16)+(octet3<<8)+octet4 ))
   local mask=$(( 0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF ))
   local network=$(( ip_int & mask))
   local broadcast=$(( network | (~mask & 0xFFFFFFFF) ))
   
################Build list of hosts to check####################

   for (( i = network + 1; i < broadcast; i++));do
      printf "%d.%d.%d.%d\n" $(( (i>>24)&255)) $(( (i>>16)&255)) $(( (i>>8)&255)) $(( i&255 ))
   done
}

get_hosts(){
  local t=$1
  if is_cidr "$t";then 
    expand_cidr "$t"
  else
    echo "$t"
  fi
}



