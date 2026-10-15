#!/bin/sh
# MOH Boot - installs the newest version published next to this file.
FORCE="$1"
BASE="${MOH_BASE:-https://raw.githubusercontent.com/mido00020/MOHBoot/main}"
T=/tmp/mohboot-install
rm -rf "$T"; mkdir -p "$T" && cd "$T" || exit 1
PY=$(command -v python3 || command -v python)
[ -n "$PY" ] || { echo "python not found"; exit 1; }
wget -q -O version.json "$BASE/version.json" || { echo "Cannot reach the update server"; exit 1; }
set -- $("$PY" -c 'import json;d=json.load(open("version.json"));print(d["ipk"],d["sha256"],d["version"])' 2>/dev/null)
IPK="$1"; SHA="$2"; VER="$3"
case "$IPK" in */*|"") echo "Bad update information"; exit 1;; enigma2-plugin-extensions-mohboot_*_all.ipk) ;; *) echo "Bad package name"; exit 1;; esac
[ ${#SHA} -eq 64 ] || { echo "Bad checksum in update information"; exit 1; }
HAVE=$(opkg status enigma2-plugin-extensions-mohboot 2>/dev/null | sed -n 's/^Version: //p' | head -n 1)
if [ "$HAVE" = "$VER" ] && [ "$FORCE" != "force" ]; then
  echo "MOH Boot $VER is already the newest version. Nothing to do."
  cd /; rm -rf "$T"
  exit 0
fi
echo "Downloading MOH Boot $VER ..."
wget -q -O "$IPK" "$BASE/$IPK" || { echo "Download failed"; exit 1; }
[ "$(sha256sum "$IPK" | cut -d' ' -f1)" = "$SHA" ] || { echo "Checksum mismatch - not installed"; rm -f "$IPK"; exit 1; }
opkg install --force-reinstall "$IPK" || { echo "Install failed"; exit 1; }
cd /; rm -rf "$T"
echo "MOH Boot $VER installed. Restarting the interface..."
sleep 2
killall -9 enigma2
