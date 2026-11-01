# AGENTS.md — Offshoots

Project notes for Offshoots. General guidelines live in `~/.codex/AGENTS.md`.

## Simulator access and isolation

This project explicitly overrides the global iPhone 18 Pro simulator allowlist.
Agents are authorized to choose and use any compatible iPhone, iPad, or Duo
simulator for project work without per-session permission. Create a dedicated
simulator instance when needed, including a separate Pro Max instance if that
model is useful. The protected resource is Geoff's active simulator instance,
identified by its UDID; never commandeer, erase, shut down, or interact with it.
Treat a booted simulator with unclear ownership as someone else's and create an
isolated instance instead. Use a unique run ID and only operate on the UDID
recorded for that run. Select an installed runtime and device type compatible
with the project's build/test requirements; install a missing runtime through
Xcode's normal flow when needed. Follow any actual OS or tool approval prompt.

# Development Commands

## Build Verification

One shared scheme, `Offshoots`. Targets: `Offshoots` and `OffshootsTests`
(Swift Testing). Unit tests cover logic. Check UI behavior on an isolated simulator allowed by the Offshoots simulator policy.

```
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build
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
  subagent must run the interactions. On the Mac mini (2026-09-24), Codex's
  own simulator tool reported "Xcode is installed but not selected", although
  `xcode-select -p` pointed at Xcode. Do not rely on that tool until this is
  fixed.
- **Uninstalling resets both permission and data.** Use it to get a clean
  first-run state.

## Test Device

The iPhone 17 Pro runs iOS 27.2 Beta 2. It builds from Xcode 27.0 on the Mac
mini (confirmed 2026-09-24).

# Docs

- The audit and plan docs live in `docs/`.
- `.gitignore` does not ignore Markdown, so a new doc is tracked with no
  exception.
- Keep CHANGELOG, DECISIONS and TODO up to date as described in `~/.codex/AGENTS.md`.
