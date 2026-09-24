# CLAUDE.md — Offshoots

Project notes for Offshoots. They override the Build Verification section in
`../CLAUDE.md`, which describes a different app (BookmarkCollections).

# Development Commands

## Build Verification

One scheme, one target: `Offshoots`. There is no test target, so testing means
building and then checking behavior on the simulator.

```
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build
```

Leave the output verbose. Do not add `-quiet`.

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
- **Tapping in the simulator:** use Xcode's device-interaction tools. Call
  `XcodeOpenWorkspace` first, then `DeviceInteractionStartSession`. A
  subagent must run the interactions. On the Mac mini (2026-09-24), Claude's
  own simulator tool reported "Xcode is installed but not selected", although
  `xcode-select -p` pointed at Xcode. Do not rely on that tool until this is
  fixed.
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
