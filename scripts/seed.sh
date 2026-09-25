#!/bin/zsh
# Load a test-data fixture into Offshoots on the simulator, then relaunch the app.
# Usage: scripts/seed.sh <fixture>   e.g. scripts/seed.sh insights-seed
# Fixtures live in docs/fixtures/. Set SIM=<UDID> to use another simulator.
set -euo pipefail

BUNDLE=com.geoffrey.silva.Offshoots
SIM=${SIM:-204520A6-E5B5-447D-8A6B-028317014DD8}   # iPhone 18 Pro, iOS 27.0, Mac mini
ROOT=${0:A:h:h}

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/seed.sh <fixture>"
  echo "Fixtures:"; ls "$ROOT/docs/fixtures" | sed 's/\.json$//; s/^/  /'
  exit 1
fi

FIXTURE="$ROOT/docs/fixtures/${1%.json}.json"
[[ -f $FIXTURE ]] || { echo "No fixture at $FIXTURE"; exit 1; }

xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl terminate "$SIM" "$BUNDLE" 2>/dev/null || true
C=$(xcrun simctl get_app_container "$SIM" "$BUNDLE" data) || { echo "Offshoots is not installed on $SIM. Build and run it once first."; exit 1; }
mkdir -p "$C/Documents"
cp "$FIXTURE" "$C/Documents/decisions.json"
xcrun simctl launch "$SIM" "$BUNDLE" >/dev/null
echo "Loaded ${FIXTURE:t} and relaunched Offshoots."
