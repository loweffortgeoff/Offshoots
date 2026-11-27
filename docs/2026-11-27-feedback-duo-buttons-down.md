# Feedback Assistant draft — iPhone Duo "buttons down"

Draft for Geoff to paste into Feedback Assistant. Source: `docs/superpowers/archive/2026-10-07-iphone-duo-findings.md`, finding 1, and DECISIONS 2026-10-07. Not filed yet.

## Fields

- **Platform / area:** iOS & iPadOS → UIKit (or "Simulator" if Feedback Assistant offers it for Xcode 27).
- **Type:** Incorrect/Unexpected Behavior.
- **Title:** iPhone Duo (closed, held buttons down): system draws upside down and third-party apps draw sideways

## Description

When the iPhone Duo is closed and held with the buttons down, the interface does not draw upright on the outer display.

- Home Screen and Settings draw upside down (rotated 180°).
- A third-party SwiftUI app (Offshoots) draws sideways (rotated 90°) in the same pose.

In the normal closed orientation, the outer display draws correctly. No public Duo API (iOS 27.1 SDK headers) lets an app control or correct this orientation, so an app cannot work around it.

## Steps to reproduce

1. Xcode 27.1 (27A9275), iOS 27.1 SDK, on a Mac mini. Boot the iPhone Duo simulator (iOS 27.1).
2. In DeviceHub, set the Duo to closed.
3. Use DeviceHub's rotate control to hold it buttons down.
4. Look at the Home Screen, then open Settings.
5. Open any third-party app that supports all orientations (for example Offshoots, which declares all four orientations).

## Expected

The Home Screen, Settings and apps draw upright on the outer display, as they do in the other closed orientations.

## Actual

The Home Screen and Settings are upside down (180°). The third-party app is sideways (90°).

## Attach

- Screenshot of Settings upside down in the closed, buttons-down pose (take it from DeviceHub's window; `simctl io screenshot` with no `--display` captures the inner display, which is black while closed).
- Optional: screenshot of the third-party app sideways in the same pose.

## Notes for Geoff

- Seen 2026-10-07 on Xcode 27.1 RC (27A9275) and the iOS 27.1 Duo simulator. Not checked again since. The Duo runtime on the Mac mini is still iOS 27.1, so a re-check there takes a few minutes and gives Apple a current repro.
- Simulator only; there is no physical Duo. The hardware re-check is on the TODO Watch List.
- No saved Settings screenshot was found in `App Images`; take a new one when you file.
