#!/bin/zsh
# Helper for the verify-offshoots skill. Usage: verify.sh <up|doctor|seed|db|down> [args]
#   up                 build Debug for the simulator, create a throwaway iPhone 18 Pro (iOS 27.2), install
#   doctor             read-only: is the sim booted, app installed, build current?
#   seed <fixture>     stop app, copy docs/fixtures/<fixture>.json in as decisions.json, relaunch (splash skipped)
#   db [title]         print count + titles from decisions.json; with a title, poll up to 20 s until it appears
#   down               delete the throwaway simulator. Evidence in $STATE/evidence is kept.
set -euo pipefail
ROOT=${0:A:h:h:h:h}
STATE=/tmp/offshoots-verify
BUNDLE=com.geoffrey.silva.Offshoots
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
APP=$STATE/dd/Build/Products/Debug-iphonesimulator/Offshoots.app
mkdir -p $STATE/evidence
sim() { [[ -f $STATE/sim ]] || { echo "No simulator. Run: verify.sh up"; exit 1; }; cat $STATE/sim; }
container() { xcrun simctl get_app_container "$(sim)" $BUNDLE data; }

case ${1:-} in
up)
  cd $ROOT
  xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' -derivedDataPath $STATE/dd build > $STATE/build.log 2>&1 \
    || { grep -m5 "error:" $STATE/build.log; echo "BUILD FAILED, see $STATE/build.log"; exit 1; }
  git rev-parse --short HEAD > $STATE/built-at
  if [[ ! -f $STATE/sim ]]; then
    xcrun simctl create verify-offshoots-$(date +%H%M%S) com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro com.apple.CoreSimulator.SimRuntime.iOS-27-2 > $STATE/sim
  fi
  xcrun simctl boot "$(sim)" 2>/dev/null || true
  xcrun simctl bootstatus "$(sim)" -b >/dev/null
  xcrun simctl install "$(sim)" $APP
  echo "READY sim=$(sim) built=$(cat $STATE/built-at)";;
doctor)
  [[ -f $STATE/sim ]] || { echo "FAIL no simulator (run up)"; exit 1; }
  xcrun simctl list devices | grep "$(sim)" | grep -q Booted && echo "ok sim booted $(sim)" || { echo "FAIL sim not booted"; exit 1; }
  xcrun simctl get_app_container "$(sim)" $BUNDLE >/dev/null 2>&1 && echo "ok app installed" || { echo "FAIL app not installed"; exit 1; }
  echo "built at $(cat $STATE/built-at 2>/dev/null || echo unknown), HEAD $(git -C $ROOT rev-parse --short HEAD)$([[ -n $(git -C $ROOT status --porcelain -- Offshoots) ]] && echo ' (+uncommitted app changes: rebuild with up)')"
  xcrun simctl spawn "$(sim)" launchctl list | grep -q UIKitApplication:$BUNDLE && echo "ok app running" || echo "note app not running";;
seed)
  F=$ROOT/docs/fixtures/${2:?fixture name, e.g. screenshots}.json; [[ -f $F ]] || { echo "no $F"; ls $ROOT/docs/fixtures; exit 1; }
  xcrun simctl terminate "$(sim)" $BUNDLE 2>/dev/null || true
  mkdir -p "$(container)/Documents"; cp $F "$(container)/Documents/decisions.json"
  xcrun simctl launch "$(sim)" $BUNDLE -lastSplashDate 9999999999 >/dev/null
  echo "seeded ${F:t}";;
db)
  for i in {1..20}; do
    out=$(python3 -I - "$(container)/Documents/decisions.json" "${2:-}" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
hit=[x for x in d if sys.argv[2] and sys.argv[2] in x['title']]
if sys.argv[2] and not hit: sys.exit(3)
print(len(d),"decisions");[print(" ",x['title'],"|",x['category'],"|",x['stakes'],"|expected",x['expected'],"|actual",x.get('actual')) for x in (hit or d)]
PY
    ) && { echo $out; exit 0; }
    sleep 1
  done; echo "FAIL '${2:-}' not in decisions.json after 20 s (the store writes a few seconds late)"; exit 1;;
down)
  [[ -f $STATE/sim ]] || exit 0
  xcrun simctl shutdown "$(sim)" 2>/dev/null || true; xcrun simctl delete "$(sim)"; rm -f $STATE/sim
  echo "deleted throwaway sim; evidence kept in $STATE/evidence";;
*) sed -n 2,8p $0; exit 1;;
esac
