#!/bin/bash
set -euo pipefail 

APP="rt-recon"
SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

############install for all users when run as root, otherwise only for the current user ###############
if [[ $EUID -eq  0 ]];then 
  PREFIX="/usr/local"
else 
  PREFIX="$HOME/.local"
fi

usage(){
    echo "Usage: ./install.sh [--prefix DIR] [--uninstall]"
    exit 1
}

ACTION="install"

while [[ $# -gt 0 ]];do 
  case "$1" in 
    --prefix)
      if [[ $# -lt 2 ]];then
         echo "Error: --prefix needs a directory"
         usage
      fi
      PREFIX="$2" 
      shift 2 ;;
    --uninstall) ACTION="uninstall";shift ;;
    *) usage;;
  esac 
done

SHARE="$PREFIX/share/$APP"
BIN="$PREFIX/bin/$APP"

##################uninstall ######################################
if [[ "$ACTION" = "uninstall" ]]; then
    rm -rf "$SHARE/lib" "$SHARE/modules" "$SHARE/main.sh" "$SHARE/config.conf" "$BIN"
    rmdir "$SHARE" 2>/dev/null || true      
    echo "$APP removed. Reports were kept."
    exit 0
fi

################required tool check################################
for cmd in bash ping nc awk sed;do 
   command -v "$cmd" > /dev/null || { echo "Error :'$cmd' is required"; exit 1;}
done

#############################install################################  
mkdir -p "$SHARE" "$PREFIX/bin"
rm -rf "$SHARE/lib" "$SHARE/modules"
cp -r "$SRC/main.sh" "$SRC/config.conf" "$SRC/lib" "$SRC/modules" "$SHARE/"
mkdir -p "$SHARE/reports"
chmod +x "$SHARE/main.sh" "$SHARE"/modules/*.sh

#######################launcher:the command users will type################ 
printf '#!/bin/bash\nexec bash "%s/main.sh" "$@"\n' "$SHARE" > "$BIN"
chmod +x "$BIN"

echo "Installed. Run: $APP --help"

case ":$PATH:" in 
   *":$PREFIX/bin:"*) ;;
   *) echo "Add to your PATH: export PATH=\"$PREFIX/bin:\$PATH\"";;
esac