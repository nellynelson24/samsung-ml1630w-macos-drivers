#!/bin/bash
# Removes the SpliX filters and the ML-1630 PPD installed by install.sh.
set -euo pipefail

FILTERDIR="$(cups-config --serverbin)/filter"
PPDDIR="/Library/Printers/PPDs/Contents/Resources"

echo "Printer queues using the ML-1630 driver (remove them with: lpadmin -x NAME):"
grep -l "ml1630.ppd" /etc/cups/ppd/*.ppd 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.ppd$//; s/^/  /' || true

echo "Removing filters and PPD (sudo will ask for your password)"
sudo rm -f "$FILTERDIR/rastertoqpdl" "$FILTERDIR/pstoqpdl" "$PPDDIR/ml1630.ppd"
echo "Done."
