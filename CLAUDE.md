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

`AnalyticsEngineTests` reads `docs/fixtures/*.json` directly, and pins "now"
to 2026-09-27. If you change a fixture, update the expected values in the
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
- **Uninstalling resets both permission and data.** Use it to get a clean
  first-run state.

## Test Device

The iPhone 17 Pro runs iOS 27.2 Beta 2. It builds from Xcode 27.0 on the Mac
mini (confirmed 2026-09-24).

# Docs

- The audit and plan docs live in `docs/`. The 2026-09-23 audit doc lists the
  remaining sections (3–6).
- `.gitignore` ignores `*.md` except `README.md`, `CHANGELOG.md`,
  `DECISIONS.md`, `TODO.md`, `CLAUDE.md` and `docs/**/*.md`. When you add a
  new root Markdown file that belongs in git, add an exception for it.
- Keep CHANGELOG, DECISIONS and TODO up to date as described in `../CLAUDE.md`.
