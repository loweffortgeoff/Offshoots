# iPhone Duo — Fold-Aware Layout Design

Date: 2026-10-07. Machine: Mac mini, Xcode 27.1 RC (27A9275).
Status: approved in conversation, awaiting written-spec review.
Related: `docs/2026-10-07-iphone-duo-findings.md`, TODO "iPhone Duo: proper fold-aware layout", DECISIONS 2026-10-07.

## Goal

Offshoots ships its GM with a proper iPhone Duo layout, not a minimum fix.

- Nothing sits on the fold when the device is partly open.
- On the open Duo in landscape, Decisions shows the list and the detail side by side.
- Every other screen stops stretching to full width.

## Constraints

- The app supports iOS 18.6. Every iOS 27.1 API sits behind `if #available(iOS 27.1, *)`.
- Other iPhones must not change.
- Use system APIs only (`ReservedRegion`, `ArrangementView`) until Duo behaviour is better understood and better examples exist. No custom hinge maths beyond reading the system's region.
- `main` builds only with Xcode 27.1 or later. This is accepted: Offshoots does not release before the Duo does, and other projects stay on regular Xcode. Only the Mac mini builds Offshoots.
- Follow `design-preferences.md`: one view per file, Dynamic Type, VoiceOver, no hardcoded font sizes.

## Out of scope

- "Buttons down" orientation bug (Apple's side; TODO tracks the Feedback Assistant report).
- Other apps (Task(ed), Aislewise, EveryPaw).
- `CameraCaptureAccessory`, `UIWindowSceneActivation`, `onHingeChange` (not needed).
- A split layout for Dashboard or Insights. Geoff reserves the right to amend this after he sees the single-column screens. See "Amendable choices".

## Probe results (2026-10-07, iPhone Duo simulator, iOS 27.1)

Throwaway probe on branch `scratch/duo-probe` (not merged). The fold is read with `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)`.

| Posture | Size (pt) | Division region |
|---|---|---|
| Closed | 466 × 678 | None. Occlusions only: camera 37 × 37 at (399, 29); status strip 84 × 170 at (382, 0). |
| Partly open, portrait | 669 × 951 | Active. Horizontal band: x0, y455, 669 × 40. Margins: top 20, bottom 20. |
| Partly open, landscape | 951 × 669 | Active. Vertical band: x455, y0, 40 × 669. Margins: leading 20, trailing 20. |
| Fully open, portrait | 669 × 951 | Inactive. Same geometry as partly open. `reservedRegions(kind: .division)` returns none. |
| Fully open, landscape | 951 × 669 | Inactive. Same geometry. Returns none. |

- The halves are about 455 pt each.
- The status strip occlusion is active in every posture. The safe area already covers it.
- Hinge status: closed 0°, partly open 127°, fully open 180°.
- Answer to findings open question 1: the division region is active only when the device is partly open.

## Design

### 1. Reading the fold and fitting screens to it

`Offshoots/Fold/` holds three files. Each holds one type.

**`FoldPosture`**: a small `Equatable` value type with two cases.

- `.flat`: no active fold. This covers every other device, the closed Duo and the fully open Duo.
- `.folded(axis, frame)`: the Duo is partly open. `axis` is the band's long axis. `frame` is the active division region's frame, in the reader's coordinate space.

**`FoldPostureReader`**: reads the posture once, at the app root (`ContentView`), and puts it in the environment as `\.foldPosture`.

- It uses a `GeometryReader` and `reservedRegions(kind: .division)`. An active region means `.folded`. No active region means `.flat`.
- On systems before iOS 27.1 it returns `.flat`.
- It does not use `onHingeChange`.

**`FoldPane`**: a wrapper applied to the content of Dashboard, Log, Insights and Settings, inside each tab's `NavigationStack`. The navigation bar and tab bar stay with the system.

- `.flat`: content is centred with a maximum width of about 600 pt. No iPhone is wider than 440 pt, so iPhones do not change.
- `.folded`, horizontal band (portrait): content fills only the top pane, above the band.
- `.folded`, vertical band (landscape): content fills only the left pane, left of the band.
- The other pane is plain background (`Color.offshootBackground`).
- The pane choice (top or left) and the maximum width are single constants in `FoldPane`.

### 2. Decisions in two panes

- **When it splits:** landscape only, and only when the screen is wide enough (at least about 900 pt). In practice this is the Duo, partly open or fully open, in landscape. Every other device keeps today's `NavigationStack`.
- **Layout:** `ArrangementView` with the `.split` style. The list is `primary` (left). The detail is `secondary` (right). When partly open, the system puts the fold between them.
- **Fully open:** there is no fold, and the split must work flat. A plan task checks this. If `ArrangementView` misbehaves flat (or closed), the fallback for that case is a plain `HStack` with a divider.
- **Selection:** `DecisionsListView` keeps its `NavigationPath`.
  - In two-pane mode the detail pane shows the last decision in the path. A row tap sets the path to that one decision. It does not push.
  - Notification taps and `ContentView.openDecision` already set the path, so they work unchanged.
  - With no selection, the detail pane shows a placeholder: an SF Symbol and "Select a decision".
- **Rows:** the row's `NavigationLink` stays. In two-pane mode the selected row is highlighted. Context menu actions stay.
- **Rotation and folding:** the path is the single source of truth. If the device rotates to portrait or folds closed with a decision selected, that decision shows as a normal pushed detail. Nothing is lost.
- **Files:** new `DecisionsSplitView.swift` (the two-pane arrangement). Small change to `DecisionsListView.swift`. `DecisionDetailView` (383 lines) is not touched; it already takes a `decision`.

### 3. Build order, testing and risks

Branch: `feature/duo-fold-layout`. Each step is a reviewable stop.

1. **Posture and pane.** Add the `Fold/` files. Apply `FoldPane` to Dashboard, Log, Insights and Settings. Geoff checks all four postures in DeviceHub. Decisions is still single column.
2. **Decisions two-pane.** Add `DecisionsSplitView` and the selection change. Geoff checks landscape, partly open and fully open. First task: confirm how `ArrangementView` behaves flat and closed; choose the fallback if needed.
3. **Sheets and polish.** Check the Edit and Mark Outcome sheets, the delete alert and the splash while folded. Check Dynamic Type and VoiceOver on the Duo. Fix anything that sits on the fold. This folds into the same branch.

Testing:

- **Unit tests** (Swift Testing) cover the pure parts only: posture from a list of regions, and the pane-frame maths. Tests inject region data, so they need no device.
- **Build** with the Xcode 27.1 RC (`DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"`), and check that the iPhone 18 Pro layout is unchanged.
- **Duo:** Geoff folds and rotates in DeviceHub and sends screenshots. Claude reads the posture from a log line, as in the probe. Screenshots must come from DeviceHub, not the simulator panel.
- Record the Xcode 27.1 requirement in DECISIONS and `CLAUDE.md`.

Risks:

- `ArrangementView` may act unexpectedly when flat or closed. Mitigation: plan task 1 of step 2, with the `HStack` fallback.
- Half-screen content (choice A) may look empty. Mitigation: the pane is one constant in `FoldPane`.
- The reader may lag when the posture changes. The probe showed it updates; step 1 checks for a visible flash.

## Amendable choices

Geoff reserves the right to change these after he sees the screens:

1. Which screens split in landscape. Today: Decisions only. Dashboard (summary and review list) and Insights (two chart columns) are the candidates.
2. Partly open, non-split screens fill one half only. Alternatives: split every screen, or full width with a gap.
3. Fully open, non-split screens use a centred column of about 600 pt. Alternatives: one half only, or full width.

The design keeps each choice in one place so that a change is small: a `FoldPane` constant, or one more `DecisionsSplitView`-style screen.

## Cleanup

- Delete `scratch/duo-probe` after Geoff agrees. It holds the throwaway probe (`FoldProbeOverlay.swift`) and must not be merged.
