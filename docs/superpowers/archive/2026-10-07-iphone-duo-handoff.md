# iPhone Duo — Handoff After the Test Session

Date: 2026-10-07. Machine: Mac mini (Xcode 27.0 and Xcode 27.1 RC 27A9275).
Findings: `docs/2026-10-07-iphone-duo-findings.md`.
Decision: DECISIONS 2026-10-07 (Offshoots does the iPhone Duo properly before the GM).

Read this first in the next session. Then read the findings doc.

## Where things stand

- The test session is done. No app code changed. `main` is at `00fdfc1` or later and is pushed.
- Offshoots builds with the Xcode 27.1 RC with no changes.
- The iPhone Duo simulator (iOS 27.1, `3744DFCD-58AD-482B-9412-2907F91DECE9`) is booted. Offshoots is installed on it, with `docs/fixtures/screenshots.json` loaded.
- Offshoots is not released. Its GM comes after the Duo ships, so it gets the full fold-aware layout, not a minimum fix.

## Work queue, in order

Each item is its own branch and its own reviewable stop.

| # | Work | Size | Where it is described |
|---|---|---|---|
| 1 | Splash fixes: centre the content on the closed Duo, and colour the launch screen | Small | TODO "iPhone Duo: the splash screen looks off"; findings #6 |
| 2 | Fold-aware layout: content off the fold, two-pane landscape | Feature: brainstorm, spec, plan | TODO "iPhone Duo: proper fold-aware layout"; findings #2 and #3 |
| 3 | Report "buttons down" to Apple | Geoff, Feedback Assistant | TODO "iPhone Duo: report buttons down"; findings #1 |
| 4 | "Not broken" pass for Task(ed), Aislewise and the other apps | Per app, later | DECISIONS 2026-10-07 |

## 1. Splash fixes (next)

Branch: `fix/duo-splash`. File: `Offshoots/SplashScreenView.swift`, plus the project build settings.

1. **Off-centre content.** The background has `.ignoresSafeArea()`; the `VStack` does not. On the closed Duo the camera and status strip take the right edge, so the left and right insets differ and the content sits left of centre. Make the horizontal padding equal on both sides: use the larger of the leading and trailing safe-area insets. Do not hardcode Duo values. The result must not change other iPhones, where the side insets are equal.
2. **White launch screen.** `INFOPLIST_KEY_UILaunchScreen_Generation = YES` with no colour, so the device shows white, then the green splash. Add a launch screen background colour that matches `Color.offshootsAccent`. An asset colour is needed for `UIColorName`; check `Assets.xcassets` for one first. Both build configurations (Debug and Release) need it.
3. Check:
   - Build with the 27.0 command in `CLAUDE.md`, and also with the 27.1 RC. This fix uses no 27.1 API, so both must pass.
   - iPhone 18 Pro (iOS 27.0): the splash still centres, with no white flash. Show the splash again with `simctl spawn <UDID> defaults delete com.geoffrey.silva.Offshoots hasSeenSplash` while the app is closed.
   - iPhone Duo, closed: Geoff checks it in DeviceHub (see "Testing on the Duo").
4. Note in the TODO that the same two fixes probably apply to every app with this splash.

## 2. Fold-aware layout (after the splash)

Start with `superpowers:brainstorming`, then a spec in `docs/superpowers/specs/`, then a plan. Do not write code before Geoff approves the spec.

Answer these questions first:

1. Does iOS report a `.division` reserved region when the Duo is fully open (flat)? Probe it with a throwaway debug view on a scratch branch. The answer decides whether "off the fold" applies only when the device is partly open.
2. Which screens get `ArrangementView` `.split` in landscape? Candidates: Dashboard (summary and review list), Decisions (list and detail), Insights (two chart columns). Log, the forms and Settings may only need to stay off the fold.
3. Do both Macs move to Xcode 27.1? The APIs are `API_AVAILABLE(ios(27.1))`. With them, `main` builds only with Xcode 27.1 or later. Check the MacBook with `xcodebuild -version` before you decide. It was last known on Xcode 27 beta.

Rules for the code:
- The app supports iOS 18.6. Wrap every 27.1 API in `if #available(iOS 27.1, *)`.
- Read the real declarations in the 27.1 SDK. Do not rely on the API images; they come from a third party. The SDK path is `/Applications/Xcode 27.1 RC.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator27.1.sdk`. SwiftUI declarations are in `SwiftUICore.swiftmodule` and `SwiftUI.swiftmodule` (`.swiftinterface` files); UIKit declarations are in `UIHinge.h`, `UIView.h` and `UIArrangementViewController.h`.
- Follow `design-preferences.md`: one view per file, Dynamic Type, VoiceOver.

## Testing on the Duo

- Use the Xcode 27.1 RC. Prefix commands with `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"`. Build with `-destination 'id=3744DFCD-58AD-482B-9412-2907F91DECE9'`.
- Only DeviceHub's own window can rotate and fold the device (rotate button; closed / partly open / fully open). `simctl` cannot. Claude's computer-use tools cannot see that window. **Geoff rotates and folds, and sends screenshots; Claude reads them.**
- The Claude simulator panel shows the raw framebuffer, not the device as it is held. Judge orientation only from DeviceHub screenshots.
- The closed outer screen is 466 × 678 pt. `simctl io screenshot` with no `--display` captures the inner screen, which is black while the device is closed. The simulator tool's `screenshot` follows the active screen.
- Geoff named the Duo for this work. The standing simulator rule in `CLAUDE.md` still applies to everything else: use the iPhone 18 Pro (iOS 27.0) and no other device. Say which device you take and when you release it.

## Prompt for the next session

> Read `docs/superpowers/plans/2026-10-07-iphone-duo-handoff.md`, then `docs/2026-10-07-iphone-duo-findings.md`. Do item 1, the splash fixes, on branch `fix/duo-splash`. Show me the plan before you change code. Stop when the branch builds on Xcode 27.0 and on the 27.1 RC and the iPhone 18 Pro check passes. I will check the closed Duo in DeviceHub.
