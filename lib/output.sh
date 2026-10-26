#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m"

################print banner function####################
print_banner (){
     
line=$(printf '%*s' "${TERM_WIDTH:-80}" '' |tr ' ' '=')
printf '%s'"${BLUE}"
echo "$line"
if command -v figlet &>/dev/null; then 
   figlet -t -c -f standard "Modular Recon Framework"
else 
    printf "Modular Recon Framework\n"
fi
printf "\n"
echo "$line"
printf '%s'"${NC}"
}

################colored output function####################
colored_output(){
  local result=$1
  local ip_port;
  local ip 
  local port
  local status
  
   status=$(echo "$result" | cut -d ']' -f1 | tr -d '[')
   ip_port=$(echo "$result" | awk '{print $2}')
   ip=$(echo "$ip_port" | cut -d ':' -f1)
   port=$(echo "$ip_port" |cut -d ':' -f2)

    if [[ $status = "OPEN" ]]; then  
        printf "${GREEN}[OPEN]${NC} %s:%s\n" "$ip" "$port"
    elif [[ $status = *"TIMEOUT"* ]]; then 
        printf "${YELLOW}[TIMEOUT]${NC} %s:%s\n" "$ip" "$port"
    else
        printf "${RED}[CLOSED]${NC} %s:%s\n" "$ip" "$port"
    fi
}

################csv output function####################
csv_init (){
    local file=$1
    if [[ ! -f "$file" ]]; then 
      echo "RT-Recon Report" > "$file"
      echo "" >> "$file"
      echo "Generated: $(date +"%Y-%m-%d %H:%M:%S")" >> "$file"
      echo "" >> "$file"
      echo "target,port,status,banner" >> "$file"
    fi 
}

csv_row (){
    local file=$1
    local target=$2
    local port=$3
    local status=$4
    local banner=$5

    banner=$(echo "$banner" | tr -d '""')
    echo "$target,$port,$status,\"$banner\"" >> "$file"
}

################html output function####################
html_init(){
    local file=$1
    if [[ ! -f "$file" ]]; then 
    echo "<html><head><style>" > "$file"
    echo "table {border-collapse: collapse; }" >> "$file"
    echo "td, th {border: 1px solid black; padding:6px; }" >> "$file"
    echo ".open {background:lightgreen; }" >> "$file"
    echo "</style></head><body>" >> "$file"
    echo "<h1>RT-Recon Report</h1>" >> "$file"
    echo "" >> "$file"
    echo "<h3>Generated: $(date +"%Y-%m-%d %H:%M:%S")</h3>" >> "$file"
    echo "" >> "$file"

    echo "<table>" >> "$file"
    echo  "<tr> <th>Host</th><th>Port</th><th>Status</th><th>Banner</th></tr>" >> "$file"
    fi 
}
html_row(){
    local file=$1
    local host=$2
    local port=$3
    local state=$4
    local banner=$5
    local css

    banner=${banner//$'\n'/}

    banner=$(echo "$banner" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    css=$(echo "$state" | tr '[:upper:]' '[:lower:]')
    echo "<tr class=\"$css\"><td>$host</td><td>$port</td><td>$state</td><td>$banner</td></tr>" >> "$file"
}


################Markdown output function####################
md_init(){
    local file=$1

    if [[ ! -f "$file" ]]; then
      echo "#RT-Recon Report" > "$file"
      echo "" >> "$file"
      echo "Generated: $(date +"%Y-%m-%d %H:%M:%S")" >> "$file"
      echo "" >> "$file"
      echo "| Host | Port | Status | Banner |" >> "$file"
      echo "|------|------|--------|--------|" >> "$file"
    fi
}

md_row(){
    local file=$1
    local host=$2
    local port=$3
    local state=$4
    local banner=$5

    banner=$(echo "$banner" | tr -d '|')

    echo "| $host | $port | $state | $banner |" >> "$file"
}






