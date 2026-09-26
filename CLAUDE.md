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
- **App Store screenshots:** `scripts/screenshots.sh` erases the iPhone 18 Pro
  Max (iOS 27.0), sets dark mode and a 9:41 status bar, builds, installs and
  loads `docs/fixtures/screenshots.json`. The fixture is anchored to 2026-09-27,
  and the script moves every date by the number of days between the anchor
  and today, so the shots never drift. `scripts/seed.sh screenshots` loads
  the same fixture without the date shift, so its dates drift after
  2026-09-27. `ScreenshotFixtureTests` pins the numbers. Capture with
  `scripts/screenshots.sh shot 01-dashboard`; files go to
  `~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/<date>/`.
  The shot list and scroll positions are at the top of the script. Do not save
  on 02 (Log) or 04 (Revisit): a save asks for notification permission.
  The 6.9" capture size is 1320 × 2868 px.
- **Insights fixtures:** `docs/fixtures/insights-seed.json` gives Good 50%,
  Top Category Tied, Trend Improving, Accuracy 67% (4 correct, 1 close,
  1 missed) and Optimistic (0.5 steps, 6 decisions) when today is 2026-09-25 to 2026-09-30. The trend windows move
  with today's date, so update the dates later. `insights-seed-too-early.json`
  gives Trend "Too early".
  `so-far-trend.json` gives Trend "So far" Improving (6 marked in July 2026,
  both 30-day windows empty), and it does not depend on today's date.
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
  iPhone 18 Pro screen is 402 × 874 pt, and the iPhone 18 Pro Max screen is
  440 × 956 pt. `sips -Z 956` scales a Pro Max capture to 1 px = 1 pt, so you
  can read tap coordinates from it (`-Z 874` for the Pro). Xcode's
  device-interaction tools (`XcodeOpenWorkspace`, then
  `DeviceInteractionStartSession`) are the backup.
- **Scrolling to an exact position:** use `touch_path` with slow steps and a
  pause before the lift. A flick keeps moving after release. The first small
  drag after the scroll stops is sometimes ignored; send it again (checked
  2026-09-26). A large navigation title (Decisions, Insights) only stays fully
  open or fully collapsed, so you cannot hold a small scroll offset there.
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
- **A test run shuts the simulator down.** After `xcodebuild … test`, the
  iPhone 18 Pro is Shutdown (checked 2026-09-25, with `name=` and `id=`).
  Boot it again with `xcrun simctl boot <UDID>` before `simctl ui`,
  `install` or `seed.sh`.
- **Reattach after a reinstall.** After `simctl install` or a reboot, the
  simulator tool's taps can stop reaching the app. Call `attach` again.
- **Do not start a swipe near the tab bar.** A swipe that starts at y ≥ 800
  on the iPhone 18 Pro taps the tab under it. Start at y = 720 or higher up.
- **Accessibility tree without VoiceOver:** `DeviceInteractionStartSession`
  with the simulator UDID, then `DeviceInteractionSynthesize` (optionally
  with `interactionCommand: "t x y"`) writes a hierarchy file with each
  element's label and traits (`Selected`). End the session afterwards.
  Coordinates in that file are device points.
- **Dynamic Type checks:** `xcrun simctl ui <UDID> content_size
  accessibility-extra-extra-extra-large`, then `large` to reset. At
  accessibility sizes, layouts switch with `dynamicTypeSize.isAccessibilitySize`
  (AnyLayout: side by side, or stacked). Chart text is capped at `.xxxLarge`.
- **Splash on first launch only.** After a fresh install the splash shows
  once for 2 seconds; taps in that time miss. Later launches skip it
  (`hasSeenSplash` in the app's plist). To see it again, uninstall, or
  `simctl spawn <UDID> defaults delete com.geoffrey.silva.Offshoots hasSeenSplash`
  with the app closed.
- **Menus close on their own.** Take a screenshot after opening a Picker
  menu and tap the item at once. A late tap can land on the row behind it;
  on 2026-09-25 one opened an App Store link in Safari from Settings.
- **Simulator tool taps:** pass `duration: 0.15`. Shorter taps sometimes miss
  a Toggle. The tool's own screenshot can lag; `xcrun simctl io` is current.
  The `text` action can drop characters: on 2026-09-26 "Test" arrived as
  "Te". Check the field in a screenshot before you rely on the text.
- **Calendar day taps need a free path.** Do not put an always-on tap
  gesture on a container that holds a graphical `DatePicker`. It takes the
  day taps, and only the month arrows still work (fixed 2026-09-26). The
  forms turn their tap-to-close-the-keyboard gesture on only while a text
  field has focus: `.gesture(_:including: focused ? .all : .subviews)`.

## Test Device

The iPhone 17 Pro runs iOS 27.2 Beta 2. It builds from Xcode 27.0 on the Mac
mini (confirmed 2026-09-24). This is a test device, mostly used to confirm projects compile and build on a live device. It is connected to Xcode as `Geoff's iPhone` 

The iPhone 17 runs iOS 27 (non Beta, stable releases). It builds from Xcode 27.0 on the Mac mini (confirmed 2026-09-26). This is the device that is referred to when "testing" or "dogfooding" an app for N number of days or weeks (whichever the situation calls for). It is connected to Xcode as `Geoffrey's iPhone` and should be considered the device of record for any out of session or longer term (>1 day) testing.

Both devices also build from Xcode 27 on the MacBook Pro. 

# Colors

Adaptive colors live in `Assets.xcassets` with light and dark values.
Xcode generates a `Color` symbol for each one (`OutcomeGood` becomes
`.outcomeGood`), so do not declare the same name in `Color+Theme.swift`:
the build fails with "invalid redeclaration". `Color+Theme.swift` keeps the
fixed raw palette (`offshoots…`) for the splash, plus `offshootPrimary` and
`outcomePending`.

On iOS 27.0 the graphical `DatePicker` draws the selected day in the label
color and ignores the tint. iOS 26.5 uses the tint (checked 2026-09-25).

Swift Charts axis labels keep the color they had at launch when light and
dark mode switch while the app runs. `CategoryBreakdownCard` uses
`.id(colorScheme)` to rebuild. To test a color change, switch the appearance
while the app is running, not only before launch.

# Docs

- The audit and plan docs live in `docs/`. The 2026-09-23 audit doc lists the
  remaining sections (5–6).
- `.gitignore` ignores `*.md` except `README.md`, `CHANGELOG.md`,
  `DECISIONS.md`, `TODO.md`, `CLAUDE.md` and `docs/**/*.md`. When you add a
  new root Markdown file that belongs in git, add an exception for it.
- Keep CHANGELOG, DECISIONS and TODO up to date as described in `../CLAUDE.md`.
