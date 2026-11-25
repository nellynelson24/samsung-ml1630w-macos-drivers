#!/bin/bash
# Installs the SpliX CUPS filters and PPD for the Samsung ML-1630 / ML-1630W
# on Apple Silicon Macs (arm64, jbigkit statically linked).
set -euo pipefail
cd "$(dirname "$0")"

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This package contains arm64 binaries for Apple Silicon Macs only." >&2
  exit 1
fi

FILTERDIR="$(cups-config --serverbin)/filter"
PPDDIR="/Library/Printers/PPDs/Contents/Resources"

# Files downloaded with a web browser carry a quarantine flag,
# and CUPS refuses to run a quarantined filter.
xattr -dr com.apple.quarantine filter ppd 2>/dev/null || true

echo "Installing filters to $FILTERDIR (sudo will ask for your password)"
sudo install -m 755 filter/rastertoqpdl filter/pstoqpdl "$FILTERDIR/"

echo "Installing PPD to $PPDDIR"
sudo install -m 644 ppd/ml1630.ppd "$PPDDIR/"

cat <<EOF

Done. Check that CUPS sees the driver:
  lpinfo -m | grep -i 1630

Add the printer (replace PRINTER_IP with your printer's address):
  lpadmin -p Samsung_ML1630W -E -v socket://PRINTER_IP:9100 -P "$PPDDIR/ml1630.ppd"

or in System Settings > Printers & Scanners > Add Printer > IP:
  Address: PRINTER_IP, Protocol: HP Jetdirect - Socket,
  Use: Select Software... > "Samsung ML-1630, SpliX"
EOF
