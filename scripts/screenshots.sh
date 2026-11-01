#!/bin/zsh
# App Store capture setup for Offshoots. Raw captures only: captions and frames
# happen in a separate finishing process.
#
# setup (the default) creates and erases only this RUN_ID's dedicated Pro Max (or Duo)
# simulator, sets dark mode and a 9:41 status bar, builds and installs the app, loads docs/fixtures/screenshots.json
# shifted from its 2026-09-27 anchor to today, skips the splash, and launches.
# Then drive the taps (Claude's simulator tool, or by hand) and capture each shot:
#
#   01-dashboard   Dashboard, top of screen. No row text half under the tab bar.
#   02-log         Log tab. Free Look Back appears before Expected Outcome.
#                  No paid controls or generated text in the 2.0 capture set.
#                  Log tab. Title "Move to the Denver office", category Work,
#                  note "Better team, longer winters. Leaning yes.", stakes High,
#                  prediction Good. Scroll about 33 pt: the leaf icon clears the
#                  Dynamic Island and the outcome labels clear the tab bar.
#                  DO NOT SAVE: a save asks for notification permission.
#   03-detail      Decisions > History > "Say yes to leading the offsite". Scroll
#                  to the bottom of the page: the result line, the personal note, the
#                  Neutral > Good timeline and the Revisit Decision button.
#   04-revisit     From 03, Revisit Decision. Pick Great, note "It led to a
#                  promotion talk." Tap the keyboard's Done. DO NOT SAVE.
#                  Cancel afterwards.
#   05-decisions   Decisions tab. The large title snaps: it stays open or
#                  collapses. Scroll about 90 pt (title collapsed) so the
#                  "Repaint the hallway myself" row sits fully above the tab bar.
#   06-accuracy    Insights, bottom of the page: Prediction Accuracy and Optimism.
#   07-patterns    Insights. Categories just under the navigation bar, with
#                  Categories and Outcomes fully in view.
#
# Scroll with slow drags that pause before lifting (Claude's simulator tool:
# touch_path), not flicks. A flick keeps moving after release.
#
# iPhone Duo: DEVICE="iPhone Duo" selects a Duo type/runtime and writes to
# Captures/<date>/duo/. Agents may change posture only in the simulator instance
# they created for this run; never operate Geoff's active Duo. App Store Connect sizes:
#   closed  1398 x 2034 (the "closed" display)  shots 01-07, same list as above
#   open    2007 x 2853 (the "open" display)    shot 08-decisions-open
# 08: fold the Duo partly open in landscape (Decisions list and detail side by
# side), select a marked decision, then capture. Scroll positions for the Duo
# are not tuned yet: check each closed shot after the first run.
#
# Usage:
#   export RUN_ID="offshoots-store-$(date +%Y%m%d-%H%M%S)"  # once per capture run
#   scripts/screenshots.sh              # setup
#   scripts/screenshots.sh shot 01-dashboard
#   scripts/screenshots.sh reload       # reset the data, no erase
#   DEVICE="iPhone Duo" scripts/screenshots.sh shot 08-decisions-open open
#
# DEVICE, SIM_DEVICE_TYPE, SIM_RUNTIME, OS, RUN_ID and SCREENSHOT_OUT_DIR override the defaults.
# Every RUN_ID creates a unique device instance; all commands in one run use the same RUN_ID.
set -euo pipefail

BUNDLE=com.geoffrey.silva.Offshoots
ROOT=${0:A:h:h}
RUN_ID=${RUN_ID:-"offshoots-store-$(date +%Y%m%d-%H%M%S)"}
DEVICE=${DEVICE:-"iPhone 18 Pro Max"}
SIM_NAME="offshoots-store-$RUN_ID"
STATE="$ROOT/build/screenshots/$RUN_ID"
UDID_FILE="$STATE/udid"
DERIVED="$STATE/dd"
SIM_DEVICE_TYPE=${SIM_DEVICE_TYPE:-}
SUBDIR=
if [[ $DEVICE == "iPhone Duo" ]]; then
  OS=${OS:-27.1}
  SUBDIR=/duo
  export DEVELOPER_DIR=${DEVELOPER_DIR:-"/Applications/Xcode.app/Contents/Developer"}
fi
OS=${OS:-27.0}
ANCHOR=2026-09-27
FIXTURE="$ROOT/docs/fixtures/screenshots.json"
OUT_DIR=${SCREENSHOT_OUT_DIR:-"$HOME/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/$(date +%F)$SUBDIR"}

# Resolve an available type from Xcode's inventory; create a new, uniquely named instance.
resolve_device_type() {
  if [[ -n $SIM_DEVICE_TYPE ]]; then echo "$SIM_DEVICE_TYPE"; return; fi
  xcrun simctl list devicetypes available --json | python3 -c '
import json, sys
name = sys.argv[1]
for device in json.load(sys.stdin)["devicetypes"]:
    if device["name"] == name:
        print(device["identifier"])
        raise SystemExit(0)
raise SystemExit(1)' "$DEVICE"
}

resolve_runtime() {
  if [[ -n ${SIM_RUNTIME:-} ]]; then echo "$SIM_RUNTIME"; return; fi
  xcrun simctl list runtimes available --json | python3 -c '
import json, sys
version = sys.argv[1]
for runtime in json.load(sys.stdin)["runtimes"]:
    if runtime["isAvailable"] and runtime["name"] == "iOS " + version:
        print(runtime["identifier"])
        raise SystemExit(0)
raise SystemExit(1)' "$OS"
}

udid() {
  [[ -s $UDID_FILE ]] || return 1
  cat "$UDID_FILE"
}

require_udid() {
  udid || { echo "No simulator recorded for RUN_ID=$RUN_ID; run scripts/screenshots.sh setup first." >&2; return 1; }
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
  mkdir -p "$STATE"
  local id
  if [[ ! -s $UDID_FILE ]]; then
    local devtype runtime
    devtype=$(resolve_device_type) || { echo "No available Xcode simulator type named '$DEVICE'; set SIM_DEVICE_TYPE to an available device type ID." >&2; exit 1; }
    runtime=$(resolve_runtime) || { echo "No available iOS $OS runtime; set SIM_RUNTIME to a compatible installed runtime." >&2; exit 1; }
    xcrun simctl create "$SIM_NAME" "$devtype" "$runtime" > "$UDID_FILE"
    printf '%s\n' "$devtype" > "$STATE/device-type"
    printf '%s\n' "$runtime" > "$STATE/runtime"
  fi
  id=$(require_udid)
  xcrun simctl list devices available -j | python3 -c 'import json,sys
id=sys.argv[1]
if not any(d["udid"]==id for group in json.load(sys.stdin)["devices"].values() for d in group): raise SystemExit(1)' "$id" || { echo "Recorded simulator $id is missing; choose a fresh RUN_ID." >&2; exit 1; }
  local developer_dir; developer_dir=$(xcode-select -p)
  local simulator_app="$developer_dir/../Applications/DeviceHub.app"
  [[ -d $simulator_app ]] || simulator_app="$developer_dir/Applications/Simulator.app"
  echo "📱 $DEVICE ($(cat "$STATE/device-type" 2>/dev/null || echo custom), $(cat "$STATE/runtime" 2>/dev/null || echo unknown runtime); UDID $id)"

  echo "🧹 Erasing this run-owned simulator for a clean state…"
  xcrun simctl shutdown "$id" 2>/dev/null || true
  xcrun simctl erase "$id"
  xcrun simctl boot "$id"
  open "$simulator_app" --args -CurrentDeviceUDID "$id"
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
  xcrun simctl spawn "$id" defaults write "$BUNDLE" lastSplashDate -float 9999999999
  xcrun simctl launch "$id" "$BUNDLE" >/dev/null

  echo "✅ Ready. Capture each shot (see the notes at the top of this script):"
  for name in 01-dashboard 02-log 03-detail 04-revisit 05-decisions 06-accuracy 07-patterns; do
    echo "   scripts/screenshots.sh shot $name"
  done
  [[ -z $SUBDIR ]] || echo "   scripts/screenshots.sh shot 08-decisions-open open   (fold the Duo first)"
  echo "   Output: $OUT_DIR"
}

# Reload the fixture without erasing the simulator, then relaunch the app
reload() {
  local id; id=$(require_udid)
  xcrun simctl terminate "$id" "$BUNDLE" 2>/dev/null || true
  local container; container=$(xcrun simctl get_app_container "$id" "$BUNDLE" data)
  shifted_fixture > "$container/Documents/decisions.json"
  xcrun simctl launch "$id" "$BUNDLE" >/dev/null
  echo "🌱 Screenshot data reloaded, shifted to today."
}

shot() {
  local name=${1:?usage: scripts/screenshots.sh shot <name> [closed|open]}
  local id; id=$(require_udid)
  mkdir -p "$OUT_DIR"
  local file="$OUT_DIR/$name.png"
  if [[ -n $SUBDIR ]]; then
    # Duo: "primary" is the closed display, "primary-1" the open one
    local display=primary want=1398x2034
    if [[ ${2:-closed} == open ]]; then display=primary-1; want=2007x2853; fi
    xcrun simctl io "$id" screenshot --display="$display" "$file"
    local got; got=$(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w "x" h}')
    [[ $got == "$want" ]] || echo "⚠️  $got, expected $want for ASC. Is the Duo in the right posture?" >&2
  else
    xcrun simctl io "$id" screenshot "$file"
  fi
  echo "📸 $file"
}

case ${1:-setup} in
  setup) setup ;;
  reload) reload ;;
  shot) shift; shot "$@" ;;
  *) echo "Usage: scripts/screenshots.sh [setup | reload | shot <name> [closed|open]]" >&2; exit 1 ;;
esac
