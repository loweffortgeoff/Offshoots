# Duo Wide Panes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the iPhone Duo in wide landscape, Insights, Dashboard and Log use both halves of the screen instead of leaving the right half empty.

**Architecture:** A shared `WidePanes` view wraps `ArrangementView` (`.split.axes(.horizontal)`), as `DecisionsSplitView` already does, so the system puts the fold between the panes. Each screen reads `foldPosture.supportsTwoPanes(width:)`, as `DecisionsListView` does, and picks one pane or two. `ContentView` passes `ownsWideLayout: true` for these screens. Selection and list rules live in small pure enums with Swift Testing tests, as `DecisionsSelection` does.

**Tech Stack:** SwiftUI, iOS 27.1 SDK fold APIs (`ArrangementView`), Swift Testing.

**Spec:** `docs/superpowers/specs/2026-10-16-duo-wide-panes-design.md`

## Global Constraints

- Branch `feature/duo-wide-panes`. Claude commits once per task. Geoff pushes.
- Build only with `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"`, on the Mac mini.
- Every fold API call sits behind `#available(iOS 27.1, *)`. The app still runs on iOS 18.6.
- Two panes only when `foldPosture.supportsTwoPanes(width:)` is true (a foldable device, width ≥ 900 pt). Nothing changes on any non-foldable iPhone, in any orientation.
- Settings, partly open portrait and fully open portrait do not change.
- `DecisionDetailView`, `DecisionsSplitView` and `DecisionsListView` are not changed.
- Each pane scrolls on its own.
- Simulator: use only iPhone 18 Pro (iOS 27.0). Say when you take it and when you release it. Only Geoff checks the Duo, in DeviceHub.

**Commands:**

- Build: `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build`
- One test suite: append `-only-testing:OffshootsTests/<Suite>` to `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer" xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test`
- Full suite: the same command with no `-only-testing`.

## Review Focus

1. **Mark an outcome on the Dashboard's right pane.** The decision leaves Ready to Review, and the pane must stay on it and show the result banner. Pinned by `DashboardSelectionTests.selectionStaysWhenItLeavesReadyToReview` (Task 2).
2. **Delete the decision on the Dashboard's right pane** (context menu in Decisions, then back to Dashboard). The pane falls back to the default and does not crash. Pinned by `DashboardSelectionTests.deletedSelectionFallsBackToDefault` (Task 2).
3. **A Log category with no decisions, or no decisions at all.** The right pane shows the all-category list, or a placeholder, never a blank pane. Pinned by `LogRecentListTests` (Task 3).
4. **A half-typed Log entry, then fold, rotate or tap a right-pane row.** The title, notes, category, stakes, expected outcome and review date survive. Pinned by the manual check in Task 3, Step 7.
5. **Accessibility text sizes in two panes.** Cards wrap inside their pane and nothing sits under the fold band. Pinned by the Dynamic Type check that Geoff does in Tasks 1–3 (the DeviceHub step).

---

### Task 1: Shared two-pane view and Insights split

**Files:**
- Create: `Offshoots/Fold/WidePanes.swift`
- Create: `Offshoots/Fold/TwoPaneReader.swift`
- Modify: `Offshoots/AnalyticsView.swift:11-75`
- Modify: `Offshoots/ContentView.swift:47` (Insights `FoldPane`)

**Interfaces:**
- Produces: `@available(iOS 27.1, *) struct WidePanes<Primary: View, Secondary: View>: View` with `init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary)`. Its body is `ArrangementView { primary } secondary: { secondary }.arrangementViewStyle(.split.axes(.horizontal))`.
- Produces: `struct TwoPaneReader<Content: View>: View` with `init(@ViewBuilder content: @escaping (Bool) -> Content)`. It reads `\.foldPosture`, takes the screen width the same way as `DecisionsListView.body` (`proxy.size.width + safeAreaInsets.leading + safeAreaInsets.trailing`), and passes `foldPosture.supportsTwoPanes(width:)` to `content`. Tasks 2 and 3 use it.

- [ ] **Step 1: Create the branch.** `git switch -c feature/duo-wide-panes` from `main`.
- [ ] **Step 2: Add `WidePanes.swift` and `TwoPaneReader.swift`** with the interfaces above. Header comment style as in `DecisionsSplitView.swift`.
- [ ] **Step 3: Split `AnalyticsView`'s cards into two `@ViewBuilder` properties.**
  - `whatYouDecideCards`: `OverallStatsCard`, `DecisionTimelineCard`, `CategoryBreakdownCard`, `OutcomeDistributionCard`.
  - `howItTurnedOutCards`: `OutcomeTrendCard`, `PredictionAccuracyCard`, `OptimismCard`, then `PatternsCard` under its existing condition.
  - One pane: one `ScrollView` with both groups in that order. The card order on a phone stays the same as on `main`.
- [ ] **Step 4: Build two panes with `TwoPaneReader` and `WidePanes`.**
  - Left: `NavigationStack` with the existing gradient, a `ScrollView` of `whatYouDecideCards`, and `.navigationTitle("Insights")` large.
  - Right: `NavigationStack` with the same gradient and a `ScrollView` of `howItTurnedOutCards`, `.navigationBarTitleDisplayMode(.inline)`, no title.
  - Padding in each pane is as today (horizontal 20, top 24, bottom 40, spacing 24).
  - With `store.decisions.isEmpty`, use one pane with `EmptyAnalyticsView`, centred across the full width (Claude's call in the spec), also in wide mode.
- [ ] **Step 5: In `ContentView`, change the Insights tab to `FoldPane(ownsWideLayout: true) { AnalyticsView() }`.**
- [ ] **Step 6: Build.** Run the build command. Expected: `** BUILD SUCCEEDED **`.
- [ ] **Step 7: Check that the iPhone 18 Pro is unchanged.** Boot it, install the app, run `scripts/seed.sh insights-seed`. Capture Insights in portrait with `xcrun simctl io <UDID> screenshot`. Expected: the same cards in the same order as on `main`.
- [ ] **Step 8: Commit.**

```bash
git add Offshoots/Fold/WidePanes.swift Offshoots/Fold/TwoPaneReader.swift Offshoots/AnalyticsView.swift Offshoots/ContentView.swift
git commit -m "Split Insights into two card groups on the wide Duo"
```

- [ ] **Step 9: Stop for Geoff.** He checks Insights partly open landscape and fully open landscape in DeviceHub, at the default size and at an accessibility size. Read the `FOLDPANE` log lines to confirm the pane fit is `fill`.

### Task 2: Dashboard with the selected decision on the right

**Files:**
- Create: `Offshoots/DashboardSelection.swift`
- Create: `OffshootsTests/DashboardSelectionTests.swift`
- Create: `Offshoots/DashboardRowSelection.swift`
- Modify: `Offshoots/DashboardView.swift`
- Modify: `Offshoots/ReadyToReviewSection.swift:37-46`
- Modify: `Offshoots/RecentDecisionsSection.swift:55-64`
- Modify: `Offshoots/ContentView.swift:29` (Dashboard `FoldPane`)

**Interfaces:**
- Consumes: `WidePanes`, `TwoPaneReader` (Task 1).
- Produces: `enum DashboardSelection { static func current(selectedID: UUID?, ready: [Decision], all: [Decision]) -> Decision? }`. Rule: the decision with `selectedID` if it is in `all`; else `ready.first`; else `all.first`; else `nil`. `all` is `store.decisions` (newest first). `ready` is `store.readyForReviewDecisions`.
- Produces: `struct DashboardRowSelection { let selectedID: UUID?; let select: (Decision) -> Void }`. `selectedID` is the resolved decision's ID, so the default row is also highlighted.

- [ ] **Step 1: Write the failing tests** in `DashboardSelectionTests` (`@MainActor struct`, use `Make.decision`):

```swift
@Test func noDecisionsSelectsNothing() {
    #expect(DashboardSelection.current(selectedID: nil, ready: [], all: []) == nil)
}

@Test func defaultIsTheFirstReadyDecision() {
    let a = Make.decision(title: "A"), b = Make.decision(title: "B")
    #expect(DashboardSelection.current(selectedID: nil, ready: [b], all: [a, b]) == b)
}

@Test func defaultIsTheMostRecentWhenNothingIsReady() {
    let a = Make.decision(title: "A"), b = Make.decision(title: "B")
    #expect(DashboardSelection.current(selectedID: nil, ready: [], all: [a, b]) == a)
}

// Review Focus 1
@Test func selectionStaysWhenItLeavesReadyToReview() {
    let a = Make.decision(title: "A"), b = Make.decision(title: "B")
    #expect(DashboardSelection.current(selectedID: a.id, ready: [b], all: [a, b]) == a)
}

// Review Focus 2
@Test func deletedSelectionFallsBackToDefault() {
    let a = Make.decision(title: "A"), b = Make.decision(title: "B")
    #expect(DashboardSelection.current(selectedID: a.id, ready: [b], all: [b]) == b)
}
```

- [ ] **Step 2: Run the tests.** `-only-testing:OffshootsTests/DashboardSelectionTests`. Expected: build fails, `DashboardSelection` not found.
- [ ] **Step 3: Implement `DashboardSelection.current`** in `Offshoots/DashboardSelection.swift`, with a doc comment that says why the selection stays (the result banner after a review).
- [ ] **Step 4: Run the tests.** Expected: 5 pass.
- [ ] **Step 5: Add `DashboardRowSelection`, and give both sections a `var selection: DashboardRowSelection? = nil`.**
  - `nil`: the row is the existing `NavigationLink { DecisionDetailView }` (the phone, unchanged).
  - Not `nil`: a `Button` that calls `select`. When `selection.selectedID == decision.id`, it gets the same stroke overlay and `.isSelected` trait as `DecisionsListView.row` (corner radius 12, `Color.offshootPrimary`, line width 2).
- [ ] **Step 6: Build Dashboard's two panes.**
  - In `DashboardView`, add `@State private var selectedID: UUID?`. Resolve with `DashboardSelection.current(selectedID:ready:all:)`.
  - A row tap sets `selectedID`.
  - Use `TwoPaneReader`. One pane: today's body, with `selection: nil`.
  - Two panes, through `WidePanes`:
    - Left: today's body, with a `DashboardRowSelection` passed to both sections.
    - Right: `NavigationStack { DecisionDetailView(decision:).id(decision.id) }`.
    - With no decisions, the right pane shows a placeholder in the style of `DecisionsSplitView.placeholder`, with symbol `checklist` and the text "Your decisions show here".
  - The selection is not carried between one pane and two, either way (Claude's call in the spec).
- [ ] **Step 7: In `ContentView`, change the Dashboard tab to `FoldPane(ownsWideLayout: true)`.**
- [ ] **Step 8: Build, then check the iPhone 18 Pro.** Run the build command. With `insights-seed` loaded, tap a Ready to Review row. Expected: it pushes the detail, as on `main`.
- [ ] **Step 9: Commit.**

```bash
git add Offshoots/DashboardSelection.swift Offshoots/DashboardRowSelection.swift OffshootsTests/DashboardSelectionTests.swift Offshoots/DashboardView.swift Offshoots/ReadyToReviewSection.swift Offshoots/RecentDecisionsSection.swift Offshoots/ContentView.swift
git commit -m "Show the selected decision beside the Dashboard on the wide Duo"
```

- [ ] **Step 10: Stop for Geoff.** He checks these in DeviceHub:
  - The default selection, and tapping a row.
  - Marking an outcome in the right pane: the pane stays on the decision and shows the banner.
  - Deleting the selected decision from the Decisions tab.
  - An accessibility text size.

### Task 3: Log with recent decisions on the right

**Files:**
- Create: `Offshoots/LogRecentList.swift`
- Create: `OffshootsTests/LogRecentListTests.swift`
- Create: `Offshoots/LogRecentPane.swift`
- Modify: `Offshoots/LogDecisionView.swift:10-260`
- Modify: `Offshoots/ContentView.swift:35, 73-80` (Log `FoldPane`, `openDecision`)

**Interfaces:**
- Consumes: `WidePanes`, `TwoPaneReader` (Task 1).
- Produces: `enum LogRecentList: Equatable { case category(DecisionCategory, [Decision]); case all([Decision]); case none; static let limit = 10; static func make(category: DecisionCategory, from all: [Decision]) -> LogRecentList }`. Rule:
  - At least one decision in `category`: `.category`, with the first `limit` of them in `all` order.
  - Otherwise, at least one decision: `.all`, with the first `limit` of `all`.
  - Otherwise: `.none`.
- Produces: `LogDecisionView` gets `var onOpenDecision: (Decision) -> Void = { _ in }`.
- Produces: `ContentView.show(_ decision: Decision)` sets `selectedTab = .decisions` and `decisionsPath = [decision]`. `openDecision(_:)` calls it after it finds the target.

- [ ] **Step 1: Write the failing tests** in `LogRecentListTests` (`@MainActor struct`):
  - `noDecisionsIsNone`: `make(category: .work, from: [])`. Expect `.none`.
  - `pickedCategoryComesFirst`: `all = [money1, work1, work2]`, `make(category: .work, …)`. Expect `.category(.work, [work1, work2])`.
  - `emptyCategoryFallsBackToAll`: `all = [money1, work1]`, `make(category: .health, …)`. Expect `.all([money1, work1])`.
  - `listStopsAtTen`: 12 work decisions. Expect `.category(.work, Array(all.prefix(10)))`.
  - `keepsStoreOrder`: `all = [work2, work1]`. Expect the same order back.
- [ ] **Step 2: Run the tests.** `-only-testing:OffshootsTests/LogRecentListTests`. Expected: build fails, `LogRecentList` not found.
- [ ] **Step 3: Implement `LogRecentList.make`** in `Offshoots/LogRecentList.swift`.
- [ ] **Step 4: Run the tests.** Expected: 5 pass.
- [ ] **Step 5: Add `LogRecentPane`.** `struct LogRecentPane: View { let list: LogRecentList; let onOpen: (Decision) -> Void }`.
  - Heading: "Recent in \(category.rawValue.capitalized)" for `.category`. This is the same name the rest of the app shows. Heading "Recent Decisions" for `.all`. The heading style follows `RecentDecisionsSection`'s header.
  - Rows: `DecisionRowView` inside a `Button` that calls `onOpen`.
  - `.none`: reuse `EmptyRecentDecisionsView`.
  - Background, padding and scrolling follow `RecentDecisionsSection` and the Log screen.
- [ ] **Step 6: Build Log's two panes inside `LogDecisionView.body`.**
  - Move the current `NavigationStack { … }` with its modifiers into a private `form` property. Every `@State` stays on `LogDecisionView`, so the values survive a layout change.
  - Use `TwoPaneReader`. One pane: `form`. Two panes: `WidePanes { form } secondary: { LogRecentPane(list: .make(category: category, from: store.decisions), onOpen: onOpenDecision) }`.
  - In `ContentView`:
    - Add `show(_:)`.
    - Pass `onOpenDecision: show` to `LogDecisionView`.
    - Change the Log tab to `FoldPane(ownsWideLayout: true)`.
- [ ] **Step 7: Build, run the full suite, then check the iPhone 18 Pro.**
  - Build. Run the full test suite. Expected: all pass.
  - The suite shuts the simulator down. Boot it again.
  - The Log tab must look as on `main`, in portrait and landscape.
  - Type a title, change the category, switch to Decisions and back. Expected: the title and category are still there.
- [ ] **Step 8: Commit.**

```bash
git add Offshoots/LogRecentList.swift Offshoots/LogRecentPane.swift OffshootsTests/LogRecentListTests.swift Offshoots/LogDecisionView.swift Offshoots/ContentView.swift
git commit -m "List recent decisions beside the Log form on the wide Duo"
```

- [ ] **Step 9: Stop for Geoff.** He checks these in DeviceHub:
  - The list follows the category picker.
  - The empty-category fallback.
  - A row tap opens that decision in Decisions.
  - With a half-typed entry, fold, rotate and tap a row. Every field survives (Review Focus 4).
  - An accessibility text size.
- [ ] **Step 10: After Geoff approves, before the merge.** Run the code-reviewer agent on the branch. Update CHANGELOG (`## In Progress`), DECISIONS (the selection model, and nothing carried between pane counts) and `CLAUDE.md` ("iPhone Duo" section: which screens split).
