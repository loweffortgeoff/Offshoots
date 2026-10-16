#!/bin/zsh
# Archive Offshoots (Release) and upload the build to App Store Connect for TestFlight.
# Usage: scripts/archive-upload.sh                 # archive, then upload
#        scripts/archive-upload.sh --archive-only  # archive and stop; nothing leaves the Mac
# Run it from a clean `main` with the build number already bumped. It needs Xcode 27.1
# or later (the fold APIs), and an Apple ID signed in to Xcode with access to team 2R5TZD4XAH.
# The archive lands in build/archive/ (ignored by git). Override the Xcode with DEVELOPER_DIR.
set -euo pipefail

ROOT=${0:A:h:h}
export DEVELOPER_DIR=${DEVELOPER_DIR:-"/Applications/Xcode.app/Contents/Developer"}
OUT=$ROOT/build/archive
ARCHIVE=$OUT/Offshoots.xcarchive

UPLOAD=1
case ${1:-} in
  "") ;;
  --archive-only) UPLOAD=0 ;;
  *) echo "Usage: scripts/archive-upload.sh [--archive-only]"; exit 1 ;;
esac

cd "$ROOT"

if [[ -n $(git status --porcelain) ]]; then
  echo "The working tree is not clean. Commit or stash first."; exit 1
fi
BRANCH=$(git branch --show-current)
[[ $BRANCH == main ]] || echo "Warning: building from '$BRANCH', not main."

# The scheme must not launch the app unlocked, or the paywall cannot be tested.
if grep -A1 'argument = "-ReflectionUnlockOnly"' Offshoots.xcodeproj/xcshareddata/xcschemes/Offshoots.xcscheme | grep -q 'isEnabled = "YES"'; then
  echo "-ReflectionUnlockOnly is enabled in the shared scheme. Disable it first."; exit 1
fi

rm -rf "$OUT"; mkdir -p "$OUT"

xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" -allowProvisioningUpdates archive

VERSION=$(plutil -extract ApplicationProperties.CFBundleShortVersionString raw "$ARCHIVE/Info.plist")
BUILD=$(plutil -extract ApplicationProperties.CFBundleVersion raw "$ARCHIVE/Info.plist")
echo "Archived Offshoots $VERSION ($BUILD) at $ARCHIVE"

if [[ $UPLOAD -eq 0 ]]; then
  echo "Archive only. Nothing was uploaded."; exit 0
fi

cat > "$OUT/ExportOptions.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>destination</key><string>upload</string>
<key>teamID</key><string>2R5TZD4XAH</string>
<key>signingStyle</key><string>automatic</string>
<key>uploadSymbols</key><true/>
</dict></plist>
PLIST

xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -exportPath "$OUT/export" -allowProvisioningUpdates

echo "Uploaded Offshoots $VERSION ($BUILD). Wait for Apple's processing email, then add the build to a tester group."
