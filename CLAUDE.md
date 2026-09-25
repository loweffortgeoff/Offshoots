# CLAUDE.md — Offshoots

Project notes for Offshoots. General guidelines live in `../CLAUDE.md`.

# Development Commands

## Build Verification

One shared scheme, `Offshoots`. Targets: `Offshoots` (the app) and
`OffshootsTests` (Swift Testing, hosted by the app). Unit tests cover logic.
Check UI behavior on the simulator.

```
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build
```

Leave the output verbose. Do not add `-quiet`.

## Tests

```
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test
```

The tests load `docs/fixtures/*.json` from the test bundle. The folder is a
synced group in `OffshootsTests` only, so tests also run on a device, and a
new fixture file is picked up with no project change. `AnalyticsEngineTests`
pins "now" to 2026-09-27. If you change a fixture, update the expected values in the
tests too.

Bundle ID: `com.geoffrey.silva.Offshoots`.

## Simulator Testing

- **Do not wait on real time. Seed data instead.** The store reads
  `Documents/decisions.json` from the app's data folder. The file is an array of
  `Decision` with ISO 8601 dates. Write backdated decisions there, then relaunch
  the app:
  ```
  C=$(xcrun simctl get_app_container <UDID> com.geoffrey.silva.Offshoots data)
  cp seed.json "$C/Documents/decisions.json"
  ```
  Terminate the app before you write the file, because the store saves on
  every change. Keys that are missing (`stakes`, `revisits`, `resolvedAt`)
  decode to their defaults.
- **Seed script:** `scripts/seed.sh <fixture>` closes the app, copies
  `docs/fixtures/<fixture>.json` in as `decisions.json` and relaunches.
  Run it with no argument to list fixtures. `SIM=<UDID>` picks another
  simulator. The app must be installed there first.
- **Insights fixtures:** `docs/fixtures/insights-seed.json` gives Good 50%,
  Top Category Tied, Trend Improving, Accuracy 67% (4 correct, 1 close,
  1 missed) and Optimistic (0.5 steps, 6 decisions) when today is 2026-09-25 to 2026-09-30. The trend windows move
  with today's date, so update the dates later. `insights-seed-too-early.json`
  gives Trend "Too early".
- **Test pushes need permission first.** `xcrun simctl push` fails with "Source
  is not authorized" until someone taps Allow in the app. The app asks the
  first time it schedules a reminder. `simctl privacy grant notifications`
  does not work. The push payload needs a `decisionID` key with the
  decision's UUID.
- **Toggle preset:** the Settings "Follow-up Reminders" toggle is the
  UserDefaults key `notificationsEnabled`. `simctl spawn … defaults write`
  before launch reaches the app. `defaults read` afterwards can return an
  out-of-date value. Read the app's own plist instead:
  `$C/Library/Preferences/com.geoffrey.silva.Offshoots.plist`.
- **Tapping in the simulator:** Claude's own simulator tool (`tap`, `swipe`)
  works on the Mac mini (checked 2026-09-25). Take screenshots with
  `xcrun simctl io <UDID> screenshot`. Coordinates are device points: the
  iPhone 18 Pro screen is 402 × 874 pt. Xcode's device-interaction tools
  (`XcodeOpenWorkspace`, then `DeviceInteractionStartSession`) are the backup.
- **Uninstalling resets both permission and data, but not a `defaults write`.**
  A value written with `simctl spawn … defaults write` lives outside the app
  container and survives an uninstall. On 2026-09-25 a leftover
  `notificationsEnabled = 0` on the iPhone 18 Pro simulator turned reminders
  off after a fresh install. Check with `simctl spawn <UDID> defaults read
  com.geoffrey.silva.Offshoots`, and clear it with `defaults delete`.
- **If every notification `add` fails, erase the simulator.** On 2026-09-25
  the iPhone 18 Pro simulator logged `Added notification request: [ hasError: 1 ]`
  on every add and showed no permission prompt. `simctl shutdown`, then
  `simctl erase`, fixed it. The erase also resets the simulator to light mode.
  Check with `simctl spawn <UDID> log show --last 1m --info --predicate
  'process == "Offshoots" AND subsystem BEGINSWITH "com.apple.UserNotifications"'`.
- **Simulator tool taps:** pass `duration: 0.15`. Shorter taps sometimes miss
  a Toggle. The tool's own screenshot can lag; `xcrun simctl io` is current.

## Test Device

The iPhone 17 Pro runs iOS 27.2 Beta 2. It builds from Xcode 27.0 on the Mac
mini (confirmed 2026-09-24).

# Colors

Adaptive colors live in `Assets.xcassets` with light and dark values.
Xcode generates a `Color` symbol for each one (`OutcomeGood` becomes
`.outcomeGood`), so do not declare the same name in `Color+Theme.swift`:
the build fails with "invalid redeclaration". `Color+Theme.swift` keeps the
fixed raw palette (`offshoots…`) for the splash, plus `offshootPrimary` and
`outcomePending`.

On iOS 27.0 the graphical `DatePicker` draws the selected day in the label
color and ignores the tint. iOS 26.5 uses the tint (checked 2026-09-25).

# Docs

- The audit and plan docs live in `docs/`. The 2026-09-23 audit doc lists the
  remaining sections (5–6).
- `.gitignore` ignores `*.md` except `README.md`, `CHANGELOG.md`,
  `DECISIONS.md`, `TODO.md`, `CLAUDE.md` and `docs/**/*.md`. When you add a
  new root Markdown file that belongs in git, add an exception for it.
- Keep CHANGELOG, DECISIONS and TODO up to date as described in `../CLAUDE.md`.
