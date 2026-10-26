# RT-Recon_Framework

RT-Recon_Framework is a reconnaissance toolkit written in native bash, designed to perform network reconnaissance and used **for authorized security assessment only.**

#### Features 
- **No external dependencies** - only depends on bash built-in features and standard linux commands
- **Live host discovery** - supports single IPs and CIDR
- **TCP port discovery** - parallelized using background process and wait concurrency for faster scans
- **Service detection** - grabs and parses banner for the report 
- **Logging** - records activity is shown in terminal and with `-l`saved to `scan.log`
- **Reports** - plain text, markdown, CSV and HTML 
- **Nmap integration** - used if nmap is available 

#### Help 
```text
 ____  _     ____                        _____                                            _    
|  _ \| |_  |  _ \ ___  ___ ___  _ __   |  ___| __ __ _ _ __ ___   _____      _____  _ __| | __
| |_) | __| | |_) / _ \/ __/ _ \| '_ \  | |_ | '__/ _` | '_ ` _ \ / _ \ \ /\ / / _ \| '__| |/ /
|  _ <| |_  |  _ <  __/ (_| (_) | | | | |  _|| | | (_| | | | | | |  __/\ V  V / (_) | |  |   < 
|_| \_\\__| |_| \_\___|\___\___/|_| |_| |_|  |_|  \__,_|_| |_| |_|\___| \_/\_/ \___/|_|  |_|\_\
                                                                         
```text  
  RT-Recon_Framework  Modular reconnaissance toolkit 
  For authorized security testing and internal red team engagement only 
 ```
```text
 ######## USAGE:
  ./main.sh --module <module_name> -t <target> -p <start_end> [-c <threads>] [-o <output_file>] [-s] [-H] [-m] [-l] [-v]

```text
 ######## MODULES:
 host_discovery     Discover live hosts in an IP or CIDR range 
 nmap_wrapper       Wrapper around nmap, if installed
 port_scan          Scan ports with configurable concurrency
 service_detect     Banner grab and service parsing on open ports
 all                Run host_discovery, port_scan and service_detect in sequence
 ```

```text
######## REQUIRED OPTIONS:
  --module <name>                    Module to run (see MODULES above)
  -t <target>                        Target IP or CIDR range (e.g. 192.168.1.10 or 192.168.1.0/24)
```

```text
######## OPTIONAL OPTIONS:
  -h, --help          Show this help menu and exit
  -p <start-end>      Port range to scan (required for port_scan/service_detect;optional for host_discovery e.g. 1-1000)
  -c <n>              Max concurrent jobs / semaphore limit (default: 20)
  -o <file>           Output file name (default: report.txt)
  -v                  Show verbose output, including closed/timed-out ports
  -s                  Write result to CSV file
  -H                  Write a colored HTML report
  -m                  Write a markdown report
  -l                  Display the content of scan.log if enabled
```

```text
######## Examples

######### Basic port scan on a single host
rt-recon --module port_scan -t 192.168.1.10 -p 1-1000

######### Host discovery across a subnet
rt-recon --module host_discovery -t 192.168.1.0/24

######### Port scan with custom concurrency
rt-recon --module port_scan -t 10.0.0.5 -p 1-65535 -c 50 -s -v

######### Full recon with TXT, CSV, HTML and Markdown reports, and logging
rt-recon --module all -t 10.0.0.5 -p 1-65535 -c 50 -o report.txt -s -H -m -l -v
```

```text
######## EXIT CODES:
  0     Success
  1     Invalid arguments or validation failure
  130   Interrupted by user (Ctrl+C)
```

#### Architecture

```text
recon_tool/
├── main.sh
├── install.sh
├── config.conf
├── readme.md
│
├── lib/
│   ├── args_validation.sh
│   ├── network.sh
│   ├── output.sh
│   ├── logging.sh
│   └── drop_in_module.sh
│
├── modules/
│   ├── host_discovery.sh
│   ├── port_scan.sh
│   ├── service_detect.sh
│   └── nmap_wrapper.sh
│
└── reports/
    └── <timestamp>/
        └── scan_result/
            ├── live_hosts.txt
            ├── <ip>_open_ports.txt
            ├── report.txt
            ├── report.md
            ├── report.html
            ├── results.csv
            └── scan.log
```

#### installation 

```bash
git clone https://github.com/Emna928/rt-recon.git
cd rt-recon
chmod +x install.sh 
sudo ./install.sh    # all users(/usr/local)
#or: ./install.sh    #current user only (~/.local, no sudo)
Rt-recon --help
```

**Note:** after a per-user install (no sudo), if `rt-recon` is not found, run
```bash
export PATH="$HOME/.local/bin:$PATH"
```

**Requirements:** `bash`, `ping`, `nc` (netcat), `awk`, `sed`. Optional: `nmap`, `figlet`.


```bash
to uninstall:
sudo ./install.sh --uninstall
```
#### Reports 

Each run creates `reports/<timestamp>/scan_result/` containing `report.txt`
and, depending on options, `scan.log` (-l), `results.csv` (-s),
`report.html` (-H) and `report.md` (-m).

| How you run it | Where reports are saved |
|---|---|
| `git clone` + `bash main.sh ...` | `reports/` inside the project folder |
| `./install.sh` or `sudo ./install.sh` | `~/.local/share/rt-recon/reports/` |

Reports are never deleted by `install.sh --uninstall`.

## Legal notice

Use this tool only on systems you own or have explicit written permission to test. Unauthorized scanning may be illegal.