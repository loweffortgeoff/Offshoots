#!/bin/zsh
# App Store capture setup for Offshoots. Raw captures only: captions and frames
# happen in a separate finishing process.
#
# setup (the default) erases the iPhone 18 Pro Max (iOS 27.0), sets dark mode and
# a 9:41 status bar, builds and installs the app, loads docs/fixtures/screenshots.json
# shifted from its 2026-09-27 anchor to today, skips the splash, and launches.
# Then drive the taps (Claude's simulator tool, or by hand) and capture each shot:
#
#   01-dashboard   Dashboard, top of screen. No row text half under the tab bar.
#   02-log         Log tab. Title "Move to the Denver office", category Work,
#                  note "Better team, longer winters. Leaning yes.", stakes High,
#                  prediction Good. Scroll until the outcome labels clear the
#                  tab bar. DO NOT SAVE: a save asks for notification permission.
#   03-detail      Decisions > History > "Say yes to leading the offsite".
#                  Show the result line and the Bad > Neutral > Good timeline.
#   04-revisit     From 03, Revisit Decision. Pick Great, note "It led to a
#                  promotion talk." DO NOT SAVE. Cancel afterwards.
#   05-decisions   Decisions tab, top of screen: Ready to Review, Upcoming, History.
#   06-accuracy    Insights. Prediction Accuracy and Optimism fully in view.
#   07-patterns    Insights. Categories and Outcomes fully in view.
#
# Usage:
#   scripts/screenshots.sh              # setup
#   scripts/screenshots.sh shot 01-dashboard
#
# DEVICE, OS and SCREENSHOT_OUT_DIR override the defaults.
set -euo pipefail

BUNDLE=com.geoffrey.silva.Offshoots
DEVICE=${DEVICE:-"iPhone 18 Pro Max"}
OS=${OS:-27.0}
ANCHOR=2026-09-27
ROOT=${0:A:h:h}
FIXTURE="$ROOT/docs/fixtures/screenshots.json"
DERIVED="$ROOT/build/screenshots-dd"
OUT_DIR=${SCREENSHOT_OUT_DIR:-"$HOME/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/$(date +%F)"}

# UDID of the available simulator named $DEVICE on iOS $OS
udid() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
name, runtime = sys.argv[1], "iOS-" + sys.argv[2].replace(".", "-")
for key, devices in json.load(sys.stdin)["devices"].items():
    if key.endswith(runtime):
        for device in devices:
            if device["name"] == name:
                print(device["udid"])
                sys.exit(0)
sys.exit(1)' "$DEVICE" "$OS"
}

require_udid() {
  udid || { echo "No available simulator named '$DEVICE' on iOS $OS." >&2; exit 1; }
}

# The fixture with every ISO 8601 date moved by (today - anchor) in whole days
shifted_fixture() {
  python3 - "$FIXTURE" "$ANCHOR" <<'PY'
import re, sys
from datetime import date, datetime, timedelta
path, anchor = sys.argv[1], date.fromisoformat(sys.argv[2])
offset = timedelta(days=(date.today() - anchor).days)
def shift(match):
    moved = datetime.strptime(match.group(0), "%Y-%m-%dT%H:%M:%SZ") + offset
    return moved.strftime("%Y-%m-%dT%H:%M:%SZ")
with open(path) as file:
    sys.stdout.write(re.sub(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", shift, file.read()))
PY
}

setup() {
  local id; id=$(require_udid)
  local developer_dir; developer_dir=$(xcode-select -p)
  local simulator_app="$developer_dir/../Applications/DeviceHub.app"
  [[ -d $simulator_app ]] || simulator_app="$developer_dir/Applications/Simulator.app"
  echo "📱 $DEVICE, iOS $OS ($id)"

  echo "🧹 Erasing for a clean state…"
  xcrun simctl shutdown "$id" 2>/dev/null || true
  xcrun simctl erase "$id"
  xcrun simctl boot "$id"
  open "$simulator_app"
  xcrun simctl bootstatus "$id" -b

  echo "🌙 Dark mode, 9:41 status bar…"
  xcrun simctl ui "$id" appearance dark
  xcrun simctl status_bar "$id" override --time "9:41" \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState discharging --batteryLevel 100

  echo "🔨 Building…"
  xcodebuild -project "$ROOT/Offshoots.xcodeproj" -scheme Offshoots -configuration Debug \
    -destination "id=$id" -derivedDataPath "$DERIVED" build
  xcrun simctl install "$id" "$DERIVED/Build/Products/Debug-iphonesimulator/Offshoots.app"

  echo "🌱 Loading the screenshot data, shifted to today…"
  local container; container=$(xcrun simctl get_app_container "$id" "$BUNDLE" data)
  mkdir -p "$container/Documents"
  shifted_fixture > "$container/Documents/decisions.json"
  xcrun simctl spawn "$id" defaults write "$BUNDLE" hasSeenSplash -bool YES
  xcrun simctl launch "$id" "$BUNDLE" >/dev/null

  echo "✅ Ready. Capture each shot (see the notes at the top of this script):"
  for name in 01-dashboard 02-log 03-detail 04-revisit 05-decisions 06-accuracy 07-patterns; do
    echo "   scripts/screenshots.sh shot $name"
  done
  echo "   Output: $OUT_DIR"
}

shot() {
  local name=${1:?usage: scripts/screenshots.sh shot <name>}
  local id; id=$(require_udid)
  mkdir -p "$OUT_DIR"
  xcrun simctl io "$id" screenshot "$OUT_DIR/$name.png"
  echo "📸 $OUT_DIR/$name.png"
}

case ${1:-setup} in
  setup) setup ;;
  shot) shift; shot "$@" ;;
  *) echo "Usage: scripts/screenshots.sh [setup | shot <name>]" >&2; exit 1 ;;
esac
