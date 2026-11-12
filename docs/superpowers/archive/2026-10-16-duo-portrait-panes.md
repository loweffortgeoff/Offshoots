# Duo Portrait Panes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the iPhone Duo partly open in portrait, Dashboard, Log, Decisions and Insights use both halves (first pane on top, second below the fold), with the same pairs as landscape.

**Architecture:** A new pure value, `PaneArrangement` (`single`, `sideBySide`, `stacked`), replaces the `Bool` "two panes" test. `FoldPosture.arrangement(width:)` decides it. `WidePanes` takes the arrangement and sets the `ArrangementView` split axis. The four screens already switch between one and two panes; they pass the arrangement through. Content, selection and row-tap rules do not change.

**Tech Stack:** SwiftUI, `ArrangementView` (iOS 27.1 SDK, behind `#available(iOS 27.1, *)`), Swift Testing. Build with Xcode 27.1 on the Mac mini.

**Spec:** `docs/superpowers/specs/2026-10-16-duo-portrait-panes-design.md` (reuses `2026-10-16-duo-wide-panes-design.md`).

## Global Constraints

- Branch `feature/duo-portrait-panes`. Never commit feature code to `main`. Claude commits. Geoff pushes.
- Builds only with Xcode 27.1 on the Mac mini: prefix commands with `DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"`. Leave `xcodebuild` output verbose (no `-quiet`).
- Fold APIs stay behind `#available(iOS 27.1, *)`. The app still runs on iOS 18.6.
- Partly open portrait numbers: 669 x 951 pt, band at y 455, 40 pt tall, 20 pt margins.
- Closed Duo, fully open Duo and every other iPhone do not change, in any orientation.
- Settings stays in one pane (`ownsWideLayout: false`).
- Content under the fold band or the floating tab bar is a failure.
- Only Geoff can fold the Duo (DeviceHub). Each "Geoff checks" step is a stop: show what changed, how to check it, and what is next.
- Use the `FOLDPANE` debug log lines to check pane edges, not pixel positions.
- Simulator rule: Claude uses only iPhone 18 Pro (iOS 27.0), passed explicitly, and says when it takes and releases it.

## Review Focus

1. Fully open portrait (`unfolded`, 669 wide) must stay `single` and keep the centred column. Test in Task 1.
2. Closed Duo (`flat`, 466 wide) and a Pro Max in landscape (`flat`, 956 wide) must stay `single`. Test in Task 1.
3. Settings (`ownsWideLayout: false`) must still fit the top half when partly open in portrait. Test in Task 1.
4. A half-typed Log entry survives partly open portrait → partly open landscape → back. Check in Task 4 (Geoff).
5. Insights with no decisions, partly open portrait: the empty state sits in the top pane, clear of the fold, and the bottom pane is plain background (as in landscape). Check in Task 2 (Geoff).

---

### Task 1: The pane arrangement rule

**Files:**
- Modify: `Offshoots/Fold/FoldPosture.swift`, `Offshoots/Fold/FoldLayout.swift` (only if a name moves), `Offshoots/Fold/TwoPaneReader.swift`, `Offshoots/Fold/FoldPane.swift` (only if it calls `supportsTwoPanes`)
- Modify (call sites, mechanical): `Offshoots/DecisionsListView.swift`
- Test: `OffshootsTests/FoldPostureTests.swift`

**Interfaces:**
- Produces:
  - `enum PaneArrangement: Equatable { case single, sideBySide, stacked }`
  - `FoldPosture.arrangement(width: CGFloat) -> PaneArrangement`
  - `TwoPaneReader` content closure becomes `(PaneArrangement) -> Content` (was `(Bool)`)
  - `FoldPosture.supportsTwoPanes(width:)` is removed. `paneFit` keeps its signature.
- Consumes: existing `FoldPosture`, `FoldLayout.usesTwoPanes(width:)`.

- [ ] **Step 1: Create the branch.** `git switch -c feature/duo-portrait-panes` from `main` (clean). Expected: `git branch --show-current` prints the branch name.

- [ ] **Step 2: Write the failing tests** in `FoldPostureTests.swift`. Use the existing `horizontalBand`, `verticalBand` fixtures. Replace `twoPanesNeedAFoldableDeviceAndAWideScreen` and edit `wideLayoutOwnerStillFitsThePaneInPortrait`:
  - `arrangementIsSideBySideInWideLandscape`: partly open landscape (`verticalBand`, width 951) and `.unfolded` at 951 give `.sideBySide`.
  - `arrangementIsStackedWhenPartlyOpenInPortrait`: `FoldPosture(regions: [horizontalBand]).arrangement(width: 669) == .stacked`.
  - `arrangementIsSingleEverywhereElse`: `.unfolded` at 669, `.flat` at 466, 440, 874 and 956 all give `.single`.
  - Change `wideLayoutOwnerStillFitsThePaneInPortrait`: the owner now gets `.fill` when partly open in portrait; `.unfolded` at 669 still gives `.centered(maxWidth: 600)`; `.flat` at 440 still `.fill`.
  - Add `nonOwnerStillFitsTheTopPaneWhenPartlyOpenInPortrait`: `paneFit(containerWidth: 669, ownsWideLayout: false) == .top(height: 435)` (Settings).

- [ ] **Step 3: Run to verify failure.**
  `DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -only-testing:OffshootsTests/FoldPostureTests test`
  Expected: build FAIL, `arrangement` and `PaneArrangement` not defined. (Takes iPhone 18 Pro; say so. A test run shuts it down.)

- [ ] **Step 4: Implement** `PaneArrangement` and `arrangement(width:)` in `FoldPosture.swift`. Order: if `self != .flat` and `FoldLayout.usesTwoPanes(width:)` → `.sideBySide`; else if `self` is `.folded(.horizontal, _)` → `.stacked`; else `.single`. In `paneFit`, replace the `ownsWideLayout, supportsTwoPanes` test with `ownsWideLayout, arrangement(width:) != .single` → `.fill`. Update `TwoPaneReader` to pass `foldPosture.arrangement(width: screenWidth)`. Update the four screens' and `DecisionsListView`'s call sites only as far as needed to compile: a screen that tested `twoPanes` now tests `arrangement != .single`, and passes `.sideBySide` behaviour unchanged. Do not change visuals in this task.

- [ ] **Step 5: Run the full test target** (same command without `-only-testing`). Expected: all pass, including the new tests.

- [ ] **Step 6: Build for the simulator** (project's Build Verification command). Expected: BUILD SUCCEEDED, no new warnings.

- [ ] **Step 7: Commit.** Stage `Offshoots/` and `OffshootsTests/FoldPostureTests.swift` only. Message: "Add PaneArrangement: partly open portrait is a stacked pair". End with the Co-Authored-By line from the session attribution.

---

### Task 2: Vertical `WidePanes` and Insights (stop 1)

**Files:**
- Modify: `Offshoots/Fold/WidePanes.swift`, `Offshoots/AnalyticsView.swift`

**Interfaces:**
- Consumes: `PaneArrangement` from Task 1.
- Produces: `WidePanes(arrangement: PaneArrangement, primary:, secondary:)`. `.sideBySide` behaves as today (split axis `.horizontal`, rail inset on the primary pane). `.stacked` uses `.arrangementViewStyle(.split.axes(.vertical))`. Passing `.single` is a programmer error: `assertionFailure` in DEBUG and treat as `.sideBySide`.

- [ ] **Step 1: Add the `arrangement` parameter** to `WidePanes`. For `.stacked`, the primary pane is cut at the fold's top edge and the secondary starts below the band (the system places the fold, as in landscape). Read the outer `safeAreaInsets.bottom` (the tab bar) the way the landscape code reads the rail inset, and give the secondary pane that inset so its last content clears the tab bar. If `.vertical` is not accepted by `.split.axes`, stop and report the compiler error: the spec's key assumption is wrong.

- [ ] **Step 2: Add a DEBUG log line** `FOLDPANE stacked primary %@ secondary %@ outerSafe %@` with each pane's size and safe-area insets (a `GeometryReader` in each pane, `#if DEBUG` only, `NSLog`, as `FoldPane` does). Geoff uses it to check the pane edges.

- [ ] **Step 3: Switch Insights** (`AnalyticsView`) to `WidePanes(arrangement:)` for both `.sideBySide` and `.stacked`. Same cards, same titles ("Insights" on top, "Outcomes" below). With no decisions: the empty state in the primary pane, `Color.offshootBackground.ignoresSafeArea()` in the secondary, for both arrangements.

- [ ] **Step 4: Build** with the project command. Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Check the iPhone 18 Pro (iOS 27.0) is unchanged.** Boot it, install, launch, open Insights, take a screenshot with `xcrun simctl io <UDID> screenshot`, and compare it with the `main` look (single column, all cards). Say you have released the simulator after.

- [ ] **Step 6: Commit.** Message: "Insights: top and bottom panes when the Duo is partly open in portrait".

- [ ] **Step 7: Stop. Geoff checks** in DeviceHub: Insights partly open portrait (top "What you decide", bottom "Outcomes"; nothing under the fold or the tab bar), then rotate to partly open landscape and back, then Insights with no decisions (Review Focus 5). Fully open portrait is unchanged. Read `FOLDPANE` lines from `simctl spawn <UDID> log show --last 30s --info --predicate 'eventMessage CONTAINS "FOLDPANE"'`. Next: Task 3.

---

### Task 3: Decisions and Dashboard (stop 2)

**Files:**
- Modify: `Offshoots/DecisionsSplitView.swift`, `Offshoots/DecisionsListView.swift`, `Offshoots/DashboardView.swift`

**Interfaces:**
- Consumes: `WidePanes(arrangement:…)`, `TwoPaneReader` closure `(PaneArrangement)`.
- Produces: `DecisionsSplitView(arrangement:selection:primary:)`.

- [ ] **Step 1: Decisions.** `DecisionsSplitView` takes the arrangement and passes it to `WidePanes`. `DecisionsListView.layout` passes the arrangement from the posture. The list's `twoPanes:` flag becomes `arrangement != .single`. Selection, pruning and `DecisionsSelection` do not change.

- [ ] **Step 2: Dashboard.** `DashboardView` passes the arrangement to `WidePanes` for both `.sideBySide` and `.stacked`. Default selection, pinning (`onChange(of: shown?.id…)`) and row highlight do not change.

- [ ] **Step 3: Build.** Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Run the full test target.** Expected: all pass.

- [ ] **Step 5: Check the iPhone 18 Pro (iOS 27.0)**: Dashboard and Decisions look the same as on `main`, in portrait and landscape (screenshots). Say when you take and release the simulator.

- [ ] **Step 6: Commit.** Message: "Decisions and Dashboard: top and bottom panes when the Duo is partly open in portrait".

- [ ] **Step 7: Stop. Geoff checks** in DeviceHub: Decisions (list top, detail bottom; select a row; delete the selected decision), Dashboard (default selection in the bottom pane, tap a row, mark an outcome and see the result banner). Check whether the bottom pane (about 456 pt minus the tab bar) feels too cramped for the detail screen: this is Geoff's call (spec, Risk 2). Next: Task 4.

---

### Task 4: Log (stop 3)

**Files:**
- Modify: `Offshoots/LogDecisionView.swift`

**Interfaces:**
- Consumes: `WidePanes(arrangement:…)`, `LogRecentPane(list:onOpen:)`.

- [ ] **Step 1: Switch Log** to `WidePanes(arrangement:)` for both arrangements. Form on top, `LogRecentPane` below. Keep the split inside `LogDecisionView.body` so the form's `@State` keeps its identity (the existing comment explains why). The `LogRecentList.make` call and its tests do not change.

- [ ] **Step 2: Build and run the full test target.** Expected: BUILD SUCCEEDED, all tests pass.

- [ ] **Step 3: Check the iPhone 18 Pro (iOS 27.0)**: Log is unchanged from `main` (portrait and landscape). Say when you take and release the simulator.

- [ ] **Step 4: Commit.** Message: "Log: form on top, recent decisions below when the Duo is partly open in portrait".

- [ ] **Step 5: Stop. Geoff checks** in DeviceHub (Review Focus 4): type half an entry, rotate the Duo to partly open landscape and back; title, notes, category and review date stay. Change the category and watch the bottom list follow. Tap a recent row and land on Decisions with that decision open. With the keyboard open the bottom half is covered: accepted.

---

### Task 5: Docs, full suite, review

**Files:**
- Modify: `CHANGELOG.md` (In Progress), `DECISIONS.md`, `TODO.md`, `CLAUDE.md` (the "Two panes in wide landscape" bullet: add the portrait pairs and `PaneArrangement`), `README.md` only if drift

- [ ] **Step 1: Run the full test suite** with the project's Tests command. Expected: all pass. Report any failure with its output.

- [ ] **Step 2: Review the diff** with the `code-reviewer` agent (fresh context, no write access). Fix what it finds, as separate commits.

- [ ] **Step 3: Run the doc-keeper ritual** (TODO, DECISIONS, CHANGELOG, README drift). Record in DECISIONS: `PaneArrangement` replaces the Bool; Settings stays single; fully open portrait unchanged; any bottom-inset finding. Mark the spec's amendable choices.

- [ ] **Step 4: Commit the docs** on the branch. Message: "Docs: Duo portrait panes in CHANGELOG, DECISIONS, TODO and CLAUDE.md".

- [ ] **Step 5: Hand over.** Geoff merges and pushes. Claude does not push the branch.
