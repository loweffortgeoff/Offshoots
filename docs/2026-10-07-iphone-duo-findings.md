# iPhone Duo findings — 2026-10-07

Test session only. No code changed.

## Setup

- Mac mini. Xcode 27.1 RC (27A9275), iOS 27.1 SDK. `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"`.
- Simulator: iPhone Duo, iOS 27.1, UDID `3744DFCD-58AD-482B-9412-2907F91DECE9`.
- Data: `docs/fixtures/screenshots.json`.
- `main` at `b420680` (includes `fe41112`, all four orientations).
- Offshoots builds with the 27.1 RC with no changes.

## How to test the Duo

- Rotate and fold only from DeviceHub's own window: rotate button, then closed / partly open / fully open. `simctl` has no rotate or fold command.
- The Claude simulator panel shows the raw framebuffer. It does not show how the device is held, so it can make a sideways layout look correct. Judge orientation from DeviceHub.
- The outer (closed) display is 466 × 678 pt. `simctl io screenshot` with no `--display` captures the inner display, which is black while the device is closed.
- Claude's computer-use tools cannot see DeviceHub's window (no accessibility access). Geoff rotates and folds; Claude reads the screenshots.

## Findings

| # | State | What | Whose side |
|---|---|---|---|
| 1 | Closed, buttons down | Offshoots draws sideways (90°). Home Screen and Settings draw upside down (180°) in the same state. | Apple/platform. iOS 27.1 or the simulator does not map this orientation to an upright interface. No Duo API controls it. |
| 2 | Partly open and fully open, both orientations | Content sits on the fold. Landscape: "10 Completed", the middle Quick Stats card, the Stakes "Medium" segment, the Insights charts and bars, every Settings row. Portrait: "Import Decisions", the Decision Activity chart, the Log Notes field. | Our code. |
| 3 | Open, landscape | The phone layout stretches to full width: one column, cards about 700 pt wide. | Our code (design). |
| 4 | Open, landscape | Tab bar is a vertical rail on the right; the status strip sits beside it. | Apple/platform. Correct. |
| 5 | Open, portrait | Content scrolls under the floating tab bar. | Apple/platform. Normal. |
| 6 | Closed, first launch | Splash content sits left of centre: it centres in the safe area, and the camera strip makes the side insets unequal. Before it, a white launch screen shows (about 3 s on the simulator), then the screen jumps to green. | Our code. The white launch screen affects every device. |

The closed outer display in its normal orientation lays out correctly.

## APIs in the iOS 27.1 SDK (checked in the headers)

Source images: `~/Documents/Dev Workstation/App Images/iPhone_Duo_APIs_1.jpg` and `_2.jpg` (third party, @ljyjeffrey). The SDK headers are the authority.

| API | In the SDK | Use for Offshoots |
|---|---|---|
| `ArrangementView` with `.split` / `.overlay` (`UIArrangementViewController`) | Yes | Finding 3: two panes, one each side of the fold. |
| `ReservedRegion`, kinds `.occlusion` and `.division`; `reservedRegions(kind:options:layoutDirectionBehavior:)` (`UIViewReservedRegion`) | Yes | Finding 2: keep text and controls off the fold (`.division`) and the camera (`.occlusion`). |
| `DeviceHinge`, `onHingeChange` (`UIHinge`, `UIHingeInteraction`, status closed / partly open / fully open, angle in radians) | Yes | Layout changes by posture, if needed. |
| `CameraCaptureAccessory`, `.sceneAccessory()` | Yes | Not used. |
| `UIWindowSceneActivation` | Not found under that name | Not used. |

All are `API_AVAILABLE(ios(27.1))`. The app supports iOS 18.6, so each use needs `if #available(iOS 27.1, *)`. `main` then builds only with Xcode 27.1 or later.

## Open questions for the fix

1. Does iOS report a `.division` region when the device is fully open (flat)? The screenshots cannot show it. Probe it in code first.
2. Which screens get a split layout in landscape: Dashboard, Decisions (list and detail), Insights?
3. Do both Macs move to Xcode 27.1? The Mac mini has the 27.1 RC. The MacBook was last known on Xcode 27 beta (not checked).
