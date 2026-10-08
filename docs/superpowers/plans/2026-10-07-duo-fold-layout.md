# iPhone Duo Fold-Aware Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **Geoff's rule:** stop at every checkpoint (Tasks 3, 5 and 6). Show what changed, how to check it, and what comes next. Do not start the next task before Geoff has seen the checkpoint.

**Goal:** On the iPhone Duo, keep content off the fold when the device is partly open, show Decisions as list plus detail in landscape, and stop the phone layout stretching on the open device.

**Architecture:** One value type (`FoldPosture`) is read once at the app root from the system's `.division` reserved region and passed down through the environment. A `FoldPane` wrapper fits each tab into one half (partly open) or a centred column (otherwise). Decisions uses `ArrangementView` with the `.split` style in wide landscape. All iOS 27.1 API sits behind `#available(iOS 27.1, *)`.

**Tech Stack:** SwiftUI, `ReservedRegion` and `ArrangementView` (iOS 27.1 SDK), Swift Testing. Xcode 27.1 RC on the Mac mini.

**Spec:** `docs/superpowers/specs/2026-10-07-duo-fold-layout-design.md`. Read it first. Probe numbers are in its "Probe results" table.

## Global Constraints

- iOS 18.6 is the minimum (`IPHONEOS_DEPLOYMENT_TARGET = 18.6`). Every iOS 27.1 API sits behind `if #available(iOS 27.1, *)`.
- Other iPhones must not change. The app is iPhone only (`TARGETED_DEVICE_FAMILY = 1`).
- System APIs only: `ReservedRegion`, `ArrangementView`. No custom hinge maths, no `onHingeChange`.
- `main` builds only with Xcode 27.1 or later, on the Mac mini. Build with `DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"`.
- `design-preferences.md`: one view or type per file, Dynamic Type, VoiceOver labels, no hardcoded font sizes, SF Symbols first, no custom `.if` modifier, no `NavigationLink` and `Button` in one `List` row.
- Branch: `feature/duo-fold-layout`. Claude commits. Geoff pushes.
- Simulators: Duo `3744DFCD-58AD-482B-9412-2907F91DECE9` (Geoff named it for this work). iPhone 18 Pro (iOS 27.0) `204520A6-E5B5-447D-8A6B-028317014DD8` for the "other iPhones unchanged" check. Say which device you take and when you release it. Only Geoff can fold and rotate the Duo, in DeviceHub. Judge orientation only from DeviceHub screenshots.
- Test files use Swift Testing and `@testable import Offshoots`, like `OffshootsTests/AnalyticsEngineTests.swift`.

## Refinements to the spec (flag these to Geoff at checkpoint 1)

1. `FoldPane` wraps each whole tab in `ContentView`, outside the tab's `NavigationStack`, not inside it. The geometry is simpler (the pane is measured from the screen edge), and the navigation bar stays inside the pane. Only `ContentView` changes for Dashboard, Log, Insights and Settings.
2. The pane edge is the region frame plus the region's own margins (the keep-out). From the probe: top pane 435 pt tall, left pane 435 pt wide, not 455 pt.
3. The Decisions path changes from `NavigationPath` to `[Decision]`. `NavigationPath` cannot be read, and the spec needs "the last decision in the path". `Decision` is already `Hashable`.
4. In wide landscape, Decisions is exempt from `FoldPane`, because its split owns the whole screen. In portrait it is wrapped like the other tabs.

## Review Focus

1. A fold region list with more than one entry: use the first, do not crash. (Task 1 test.)
2. A degenerate region (width equals height): treat it as a horizontal band, do not crash. (Task 1 test.)
3. The selected decision is deleted while shown in the detail pane: the pane shows the placeholder, not a stale detail. (Task 4 test.)
4. The device rotates to portrait or folds closed with a decision selected: the decision stays as a pushed detail. (Task 4 manual check on the Duo, Task 6.)
5. A reminder tap arrives while the Duo is in two-pane landscape: the tapped decision shows in the detail pane. (Task 6 manual check.)

## File Structure

Create:
- `Offshoots/Fold/FoldRegion.swift`: plain value (`frame`, `margins`) so the logic is testable without the SDK type.
- `Offshoots/Fold/FoldLayout.swift`: constants (`readableMaxWidth` 600, `twoPaneMinWidth` 900) and `usesTwoPanes(width:)`.
- `Offshoots/Fold/FoldPosture.swift`: `FoldPosture` (`.flat` or `.folded`) and `PaneFit`, with the pure pane maths.
- `Offshoots/Fold/FoldPostureReader.swift`: reads the region, owns the `\.foldPosture` environment entry.
- `Offshoots/Fold/FoldPane.swift`: the wrapper view.
- `Offshoots/DecisionsSelection.swift`: pure helper that picks the selected decision.
- `Offshoots/DecisionsSplitView.swift`: the `ArrangementView` for list plus detail.
- `OffshootsTests/FoldPostureTests.swift`, `OffshootsTests/DecisionsSelectionTests.swift`.

Modify: `Offshoots/ContentView.swift`, `Offshoots/DecisionsListView.swift`.

The project uses synced folders, so new files need no project edit.

---

### Task 1: Fold value types and pane maths

**Files:**
- Create: `Offshoots/Fold/FoldRegion.swift`, `Offshoots/Fold/FoldLayout.swift`, `Offshoots/Fold/FoldPosture.swift`
- Test: `OffshootsTests/FoldPostureTests.swift`

**Interfaces:**
- Produces: `FoldRegion(frame: CGRect, margins: EdgeInsets)`; `FoldPosture` with `init(regions: [FoldRegion])`; `FoldPosture.paneFit(containerWidth: CGFloat, ownsWideLayout: Bool) -> PaneFit`; `PaneFit` cases `.fill`, `.centered(maxWidth: CGFloat)`, `.top(height: CGFloat)`, `.leading(width: CGFloat)`; `FoldLayout.usesTwoPanes(width: CGFloat) -> Bool`.

- [ ] **Step 1: Make the branch and take the iPhone 18 Pro baseline on `main`**

```bash
cd /Users/geoffreysilva/Developer/Offshoots
git checkout main && git pull --rebase
git checkout -b feature/duo-fold-layout
export DEVELOPER_DIR="/Applications/Xcode 27.1 RC.app/Contents/Developer"
P=204520A6-E5B5-447D-8A6B-028317014DD8
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" -derivedDataPath /private/tmp/claude-501/fold-dd build 2>&1 | tail -3
xcrun simctl boot $P 2>/dev/null; xcrun simctl status_bar $P override --time 9:41
xcrun simctl install $P "$(find /private/tmp/claude-501/fold-dd -name Offshoots.app -path '*iphonesimulator*' | head -1)"
scripts/seed.sh screenshots
```

Say "I take iPhone 18 Pro (iOS 27.0)". Then, for each of the five tabs (tap the tab, wait one second), save a screenshot to the scratchpad: `xcrun simctl io $P screenshot "$SCRATCH/base-<tab>.png"`. Record the `md5` of each file. Expected: five PNGs. (Tap with the simulator tool, `duration: 0.15`. Check the screen changed after each tap.)

- [ ] **Step 2: Write the failing tests**

Create `OffshootsTests/FoldPostureTests.swift`:

```swift
//
//  FoldPostureTests.swift
//  OffshootsTests
//

import Foundation
import SwiftUI
import Testing
@testable import Offshoots

/// Region numbers come from the 2026-10-07 iPhone Duo probe (see the fold layout spec).
@MainActor
struct FoldPostureTests {

    /// Partly open, portrait: 669 x 951 screen
    static let horizontalBand = FoldRegion(
        frame: CGRect(x: 0, y: 455, width: 669, height: 40),
        margins: EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
    )

    /// Partly open, landscape: 951 x 669 screen
    static let verticalBand = FoldRegion(
        frame: CGRect(x: 455, y: 0, width: 40, height: 669),
        margins: EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
    )

    @Test func noRegionsIsFlat() {
        #expect(FoldPosture(regions: []) == .flat)
    }

    @Test func horizontalBandKeepsOutTheBandAndItsMargins() {
        let posture = FoldPosture(regions: [Self.horizontalBand])
        #expect(posture == .folded(bandAxis: .horizontal, keepOut: CGRect(x: 0, y: 435, width: 669, height: 80)))
    }

    @Test func verticalBandKeepsOutTheBandAndItsMargins() {
        let posture = FoldPosture(regions: [Self.verticalBand])
        #expect(posture == .folded(bandAxis: .vertical, keepOut: CGRect(x: 435, y: 0, width: 80, height: 669)))
    }

    @Test func horizontalBandFitsTheTopPane() {
        let posture = FoldPosture(regions: [Self.horizontalBand])
        #expect(posture.paneFit(containerWidth: 669, ownsWideLayout: false) == .top(height: 435))
    }

    @Test func verticalBandFitsTheLeadingPane() {
        let posture = FoldPosture(regions: [Self.verticalBand])
        #expect(posture.paneFit(containerWidth: 951, ownsWideLayout: false) == .leading(width: 435))
    }

    @Test func flatFitsACentredReadableColumn() {
        #expect(FoldPosture.flat.paneFit(containerWidth: 951, ownsWideLayout: false) == .centered(maxWidth: 600))
        #expect(FoldPosture.flat.paneFit(containerWidth: 440, ownsWideLayout: false) == .centered(maxWidth: 600))
    }

    @Test func wideLayoutOwnerFillsTheScreenInWideLandscape() {
        let folded = FoldPosture(regions: [Self.verticalBand])
        #expect(folded.paneFit(containerWidth: 951, ownsWideLayout: true) == .fill)
        #expect(FoldPosture.flat.paneFit(containerWidth: 951, ownsWideLayout: true) == .fill)
    }

    @Test func wideLayoutOwnerStillFitsThePaneInPortraitAndOnPhones() {
        let folded = FoldPosture(regions: [Self.horizontalBand])
        #expect(folded.paneFit(containerWidth: 669, ownsWideLayout: true) == .top(height: 435))
        #expect(FoldPosture.flat.paneFit(containerWidth: 440, ownsWideLayout: true) == .centered(maxWidth: 600))
    }

    // Review Focus 1: more than one region
    @Test func usesTheFirstRegionWhenThereAreSeveral() {
        let posture = FoldPosture(regions: [Self.verticalBand, Self.horizontalBand])
        #expect(posture == FoldPosture(regions: [Self.verticalBand]))
    }

    // Review Focus 2: a square region
    @Test func squareRegionCountsAsHorizontal() {
        let square = FoldRegion(frame: CGRect(x: 10, y: 100, width: 40, height: 40), margins: EdgeInsets())
        #expect(FoldPosture(regions: [square]) == .folded(bandAxis: .horizontal, keepOut: CGRect(x: 10, y: 100, width: 40, height: 40)))
    }

    @Test func twoPanesNeedAWideScreen() {
        #expect(FoldLayout.usesTwoPanes(width: 951))
        #expect(FoldLayout.usesTwoPanes(width: 900))
        #expect(!FoldLayout.usesTwoPanes(width: 899))
        #expect(!FoldLayout.usesTwoPanes(width: 440))
    }
}
```

- [ ] **Step 3: Run the tests and confirm they fail to compile**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" -only-testing:OffshootsTests/FoldPostureTests test 2>&1 | grep -E "error:|Test Suite|TEST" | head
```

Expected: compile errors, "cannot find 'FoldRegion' in scope".

- [ ] **Step 4: Write the three source files**

`Offshoots/Fold/FoldRegion.swift`:

```swift
//
//  FoldRegion.swift
//  Offshoots
//

internal import SwiftUI

/// One reserved region as the app needs it. A plain copy of the system's
/// `ReservedRegion`, so the layout maths is testable without the iOS 27.1 SDK type.
struct FoldRegion: Equatable {
    var frame: CGRect
    var margins: EdgeInsets
}
```

`Offshoots/Fold/FoldLayout.swift`:

```swift
//
//  FoldLayout.swift
//  Offshoots
//

internal import SwiftUI

/// The numbers the fold layout uses. Change a number here, not in a view.
enum FoldLayout {
    /// Widest a column grows when no fold is active
    static let readableMaxWidth: CGFloat = 600
    /// Narrowest screen that gets two panes. The open Duo in landscape is 951 pt;
    /// the widest iPhone is 440 pt.
    static let twoPaneMinWidth: CGFloat = 900

    static func usesTwoPanes(width: CGFloat) -> Bool {
        width >= twoPaneMinWidth
    }
}
```

`Offshoots/Fold/FoldPosture.swift`:

```swift
//
//  FoldPosture.swift
//  Offshoots
//

internal import SwiftUI

/// Whether a fold is in the way. `.flat` covers every other device, the closed Duo
/// and the fully open Duo. `.folded` means the Duo is partly open.
enum FoldPosture: Equatable {
    case flat
    /// `bandAxis` is the long axis of the band. `keepOut` is the band plus its margins,
    /// in screen coordinates.
    case folded(bandAxis: Axis, keepOut: CGRect)

    init(regions: [FoldRegion]) {
        guard let region = regions.first else {
            self = .flat
            return
        }
        let frame = region.frame
        let margins = region.margins
        let keepOut = CGRect(
            x: frame.minX - margins.leading,
            y: frame.minY - margins.top,
            width: frame.width + margins.leading + margins.trailing,
            height: frame.height + margins.top + margins.bottom
        )
        self = .folded(bandAxis: frame.width >= frame.height ? .horizontal : .vertical, keepOut: keepOut)
    }
}

/// How a screen sits on the display
enum PaneFit: Equatable {
    /// Use the whole screen
    case fill
    /// A centred column, no wider than `maxWidth`
    case centered(maxWidth: CGFloat)
    /// The pane above the fold
    case top(height: CGFloat)
    /// The pane left of the fold
    case leading(width: CGFloat)
}

extension FoldPosture {
    /// `ownsWideLayout` is true for a screen that builds its own two panes on a wide screen.
    func paneFit(containerWidth: CGFloat, ownsWideLayout: Bool) -> PaneFit {
        if ownsWideLayout, FoldLayout.usesTwoPanes(width: containerWidth) {
            return .fill
        }
        switch self {
        case .flat:
            return .centered(maxWidth: FoldLayout.readableMaxWidth)
        case .folded(.horizontal, let keepOut):
            return .top(height: keepOut.minY)
        case .folded(.vertical, let keepOut):
            return .leading(width: keepOut.minX)
        }
    }
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

Same command as Step 3. Expected: `** TEST SUCCEEDED **`, all 11 tests pass. (The test run shuts the simulator down; boot it again with `xcrun simctl boot $P` before any later step that needs it.)

- [ ] **Step 6: Commit**

```bash
git add Offshoots/Fold OffshootsTests/FoldPostureTests.swift
git commit -m "Add fold posture value types and pane maths

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Posture reader, pane wrapper and the four tabs

**Files:**
- Create: `Offshoots/Fold/FoldPostureReader.swift`, `Offshoots/Fold/FoldPane.swift`
- Modify: `Offshoots/ContentView.swift`

**Interfaces:**
- Consumes: `FoldRegion`, `FoldPosture`, `PaneFit` from Task 1.
- Produces: `EnvironmentValues.foldPosture: FoldPosture`; `View.readsFoldPosture()`; `FoldPane(ownsWideLayout: Bool = false) { content }`.

- [ ] **Step 1: Write the reader**

`Offshoots/Fold/FoldPostureReader.swift`:

```swift
//
//  FoldPostureReader.swift
//  Offshoots
//

internal import SwiftUI

extension EnvironmentValues {
    /// Whether a fold is in the way. `.flat` unless the Duo is partly open.
    @Entry var foldPosture: FoldPosture = .flat
}

extension View {
    /// Reads the fold once and passes it to every view below through `\.foldPosture`.
    func readsFoldPosture() -> some View {
        modifier(FoldPostureReader())
    }
}

private struct FoldPostureReader: ViewModifier {
    @State private var posture: FoldPosture = .flat

    func body(content: Content) -> some View {
        content
            .background { RegionReader(posture: $posture) }
            .environment(\.foldPosture, posture)
    }
}

private struct RegionReader: View {
    @Binding var posture: FoldPosture

    var body: some View {
        if #available(iOS 27.1, *) {
            DivisionRegionReader(posture: $posture)
        } else {
            Color.clear
        }
    }
}

@available(iOS 27.1, *)
private struct DivisionRegionReader: View {
    @Binding var posture: FoldPosture

    var body: some View {
        GeometryReader { proxy in
            let regions = proxy.reservedRegions(kind: .division).map {
                FoldRegion(frame: $0.frame, margins: $0.margins)
            }
            Color.clear
                .onChange(of: regions, initial: true) { _, new in
                    posture = FoldPosture(regions: new)
                    #if DEBUG
                    NSLog("FOLDPOSTURE %@", String(describing: posture))
                    #endif
                }
        }
        .ignoresSafeArea()
    }
}
```

- [ ] **Step 2: Write the pane wrapper**

`Offshoots/Fold/FoldPane.swift`:

```swift
//
//  FoldPane.swift
//  Offshoots
//

internal import SwiftUI

/// Fits a whole tab to the display: one half when the Duo is partly open,
/// a centred readable column otherwise. Other iPhones are narrower than the
/// column, so nothing changes for them.
struct FoldPane<Content: View>: View {
    @Environment(\.foldPosture) private var posture
    private let ownsWideLayout: Bool
    private let content: Content

    /// Pass `ownsWideLayout: true` for a screen that builds its own two panes on a wide screen.
    init(ownsWideLayout: Bool = false, @ViewBuilder content: () -> Content) {
        self.ownsWideLayout = ownsWideLayout
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            let fit = posture.paneFit(containerWidth: screenWidth, ownsWideLayout: ownsWideLayout)
            pane(for: fit)
                .onChange(of: fit, initial: true) { _, new in
                    #if DEBUG
                    NSLog("FOLDPANE fit %@ width %.0f safe %@", String(describing: new), screenWidth, String(describing: proxy.safeAreaInsets))
                    #endif
                }
        }
        .background(Color.offshootBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func pane(for fit: PaneFit) -> some View {
        switch fit {
        case .fill:
            content
        case .centered(let maxWidth):
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        case .top(let height):
            content
                .frame(height: height)
                .frame(maxHeight: .infinity, alignment: .top)
        case .leading(let width):
            content
                .frame(width: width)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

- [ ] **Step 3: Wire it into `ContentView`**

In `Offshoots/ContentView.swift`, wrap the Dashboard, Log, Insights and Settings views in `FoldPane { … }` and add `.readsFoldPosture()` after `.tint(...)`. Leave the Decisions tab as it is for now. Replace the `TabView` block's opening and the four tab bodies like this (the `.tag` and `.tabItem` modifiers move onto the `FoldPane`):

```swift
        TabView(selection: $selectedTab) {
            FoldPane { DashboardView(selectedTab: $selectedTab, logDraft: $logDraft) }
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            FoldPane { LogDecisionView(selectedTab: $selectedTab, draft: $logDraft) }
                .tag(AppTab.log)
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }

            DecisionsListView(path: $decisionsPath)
                .tag(AppTab.decisions)
                .tabItem {
                    Label("Decisions", systemImage: "checklist")
                }

            FoldPane { AnalyticsView() }
                .tag(AppTab.insights)
                .tabItem {
                    Label("Insights", systemImage: "brain.head.profile")
                }

            FoldPane { SettingsView() }
                .tag(AppTab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.offshootPrimary)
        .readsFoldPosture()
```

- [ ] **Step 4: Build with the Xcode 27.1 RC**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|warning:.*Fold|BUILD"
```

Expected: `** BUILD SUCCEEDED **`, no warnings in the Fold files. If `@Entry` or `reservedRegions` does not compile, read the real declaration in `SwiftUICore.swiftinterface` (the SDK path is in the spec) and fix the call, not the design.

- [ ] **Step 5: Run the whole test suite**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" test 2>&1 | grep -E "error:|TEST|Executed"
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add Offshoots/Fold Offshoots/ContentView.swift
git commit -m "Fit Dashboard, Log, Insights and Settings to the fold

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Checkpoint 1 — check the four tabs (STOP for Geoff)

**Files:** none.

- [ ] **Step 1: Prove other iPhones are unchanged**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" -derivedDataPath /private/tmp/claude-501/fold-dd build 2>&1 | tail -2
xcrun simctl boot $P 2>/dev/null; xcrun simctl status_bar $P override --time 9:41
xcrun simctl install $P "$(find /private/tmp/claude-501/fold-dd -name Offshoots.app -path '*iphonesimulator*' | head -1)"
scripts/seed.sh screenshots
```

Take the five tab screenshots again, as in Task 1 Step 1, into `after-<tab>.png`. Compare the `md5` of each pair. If a pair differs, open both images and describe the difference. A difference is a bug to fix before the checkpoint. Then run `xcrun simctl status_bar $P clear`, and say "I release iPhone 18 Pro".

- [ ] **Step 2: Install on the Duo**

```bash
D=3744DFCD-58AD-482B-9412-2907F91DECE9
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$D" -derivedDataPath /private/tmp/claude-501/fold-dd build 2>&1 | tail -2
xcrun simctl terminate $D com.geoffrey.silva.Offshoots 2>/dev/null
xcrun simctl install $D "$(find /private/tmp/claude-501/fold-dd -name Offshoots.app -path '*iphonesimulator*' | head -1)"
xcrun simctl launch $D com.geoffrey.silva.Offshoots
```

- [ ] **Step 3: Ask Geoff to set each posture, and read the log after each**

Postures, in order: closed; partly open portrait; partly open landscape; fully open portrait; fully open landscape. After each, read:

```bash
xcrun simctl spawn $D log show --last 30s --info --predicate 'eventMessage CONTAINS "FOLDPOSTURE" OR eventMessage CONTAINS "FOLDPANE"' | grep -v "^Filtering\|^Timestamp"
```

Expected: closed and fully open give `flat` and `centered(maxWidth: 600.0)`; partly open portrait gives `top(height: 435.0)`; partly open landscape gives `leading(width: 435.0)`. If the safe-area insets in the `FOLDPANE` line are not zero, the top pane may be shorter than the fold by that amount. Note the numbers for Geoff.

- [ ] **Step 4: Stop and show Geoff**

Report: what changed (four tabs fit the fold), how he checks it (DeviceHub: each tab, each posture, screenshots from DeviceHub), what to look for (nothing on the fold; the blank half looks acceptable; the tab bar is where he expects), the four refinements to the spec, and that Decisions is still single column. Next is Task 4. Wait for his go.

---

### Task 4: Decisions in two panes

**Files:**
- Create: `Offshoots/DecisionsSelection.swift`, `Offshoots/DecisionsSplitView.swift`
- Modify: `Offshoots/DecisionsListView.swift`, `Offshoots/ContentView.swift`
- Test: `OffshootsTests/DecisionsSelectionTests.swift`

**Interfaces:**
- Consumes: `FoldLayout.usesTwoPanes(width:)`, `FoldPane(ownsWideLayout:)` from Tasks 1 and 2. `DecisionFactory` in `OffshootsTests/DecisionFactory.swift` (read it for the way tests build a `Decision`).
- Produces: `DecisionsSelection.current(path: [Decision], in decisions: [Decision]) -> Decision?`; `DecisionsSplitView(selection:primary:)`; `DecisionsListView(path: Binding<[Decision]>)`.

- [ ] **Step 1: Write the failing selection tests**

Read `OffshootsTests/DecisionFactory.swift` and use its helper to build decisions. Create `OffshootsTests/DecisionsSelectionTests.swift`:

```swift
//
//  DecisionsSelectionTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct DecisionsSelectionTests {

    @Test func emptyPathSelectsNothing() throws {
        let decisions = try Fixture.load("insights-seed")
        #expect(DecisionsSelection.current(path: [], in: decisions) == nil)
    }

    @Test func lastDecisionInThePathIsSelected() throws {
        let decisions = try Fixture.load("insights-seed")
        let path = [decisions[0], decisions[1]]
        #expect(DecisionsSelection.current(path: path, in: decisions) == decisions[1])
    }

    // Review Focus 3: the selected decision was deleted
    @Test func deletedDecisionSelectsNothing() throws {
        let decisions = try Fixture.load("insights-seed")
        let remaining = Array(decisions.dropFirst())
        #expect(DecisionsSelection.current(path: [decisions[0]], in: remaining) == nil)
    }
}
```

- [ ] **Step 2: Run them and confirm they fail**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" -only-testing:OffshootsTests/DecisionsSelectionTests test 2>&1 | grep -E "error:|TEST"
```

Expected: compile error, "cannot find 'DecisionsSelection' in scope".

- [ ] **Step 3: Write the selection helper**

`Offshoots/DecisionsSelection.swift`:

```swift
//
//  DecisionsSelection.swift
//  Offshoots
//

/// Which decision the detail pane shows. The path is the one source of truth:
/// the last decision in it is the selected one, if it still exists.
enum DecisionsSelection {
    static func current(path: [Decision], in decisions: [Decision]) -> Decision? {
        guard let last = path.last, decisions.contains(where: { $0.id == last.id }) else {
            return nil
        }
        return last
    }
}
```

Run the Step 2 command again. Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 4: Write the split view**

`Offshoots/DecisionsSplitView.swift`:

```swift
//
//  DecisionsSplitView.swift
//  Offshoots
//

internal import SwiftUI

/// List on one side, detail on the other. When the Duo is partly open, the system
/// puts the fold between the two.
@available(iOS 27.1, *)
struct DecisionsSplitView<Primary: View>: View {
    @Environment(DecisionStore.self) private var store
    let selection: Decision?
    private let primary: Primary

    init(selection: Decision?, @ViewBuilder primary: () -> Primary) {
        self.selection = selection
        self.primary = primary()
    }

    var body: some View {
        ArrangementView {
            primary
        } secondary: {
            NavigationStack {
                if let selection {
                    DecisionDetailView(decision: selection)
                        .id(selection.id)
                } else {
                    placeholder
                }
            }
        }
        .arrangementViewStyle(.split.axes(.horizontal))
    }

    private var placeholder: some View {
        ZStack {
            Color.offshootBackground
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.largeTitle)
                    .foregroundStyle(Color.offshootPrimary.opacity(0.6))
                    .accessibilityHidden(true)
                Text("Select a decision")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

If `.split.axes(.horizontal)` puts the panes one above the other on the Duo (checkpoint 2 shows this), change `.horizontal` to `.vertical`. Do not guess: build it and look.

- [ ] **Step 5: Change `DecisionsListView` to the `[Decision]` path and two modes**

In `Offshoots/DecisionsListView.swift`:

1. Change `@Binding var path: NavigationPath` to `@Binding var path: [Decision]`. In the `#Preview`, change `.constant(NavigationPath())` to `.constant([])`.
2. Replace `var body: some View { NavigationStack(path: $path) { … } .sheet … .alert … }` so the `NavigationStack` content moves into two helpers. The new top of the file after the properties:

```swift
    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            layout(twoPanes: FoldLayout.usesTwoPanes(width: screenWidth))
        }
        .sheet(item: $decisionToEdit) { decision in
            EditDecisionView(decision: decision)
        }
        .alert("Delete Decision?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                decisionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let decision = decisionToDelete {
                    store.delete(decision)
                    decisionToDelete = nil
                }
            }
        } message: {
            if let decision = decisionToDelete {
                Text("Are you sure you want to delete \"\(decision.title)\"? This action cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private func layout(twoPanes: Bool) -> some View {
        if twoPanes, #available(iOS 27.1, *) {
            DecisionsSplitView(selection: DecisionsSelection.current(path: path, in: store.decisions)) {
                NavigationStack {
                    listContent(twoPanes: true)
                }
            }
        } else {
            NavigationStack(path: $path) {
                listContent(twoPanes: false)
                    .navigationDestination(for: Decision.self) { decision in
                        DecisionDetailView(decision: decision)
                    }
            }
        }
    }

    private func listContent(twoPanes: Bool) -> some View {
        ZStack {
            Color.offshootBackground
                .ignoresSafeArea()

            if store.decisions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        decisionSection("Ready to Review", icon: "bell.badge.fill", color: .offshootPrimary,
                                        decisions: store.readyForReviewDecisions, twoPanes: twoPanes)
                        decisionSection("Upcoming", icon: "hourglass.circle.fill", color: .outcomePending,
                                        decisions: store.upcomingDecisions, twoPanes: twoPanes)
                        decisionSection("History", icon: "checkmark.circle.fill", color: .offshootPrimary,
                                        decisions: store.historyDecisions, twoPanes: twoPanes)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Decisions")
        .navigationBarTitleDisplayMode(.large)
    }
```

3. Add a `twoPanes: Bool` parameter to `decisionSection(...)`, and replace the `NavigationLink(value: decision) { … }.buttonStyle(.plain).contextMenu { … }` row with a call to a new `row(_:twoPanes:)`:

```swift
    @ViewBuilder
    private func row(_ decision: Decision, twoPanes: Bool) -> some View {
        let rowView = DecisionRowView(decision: decision, isReadyForReview: decision.isReadyForReview(asOf: store.today))
        if twoPanes {
            Button {
                path = [decision]
            } label: {
                rowView
            }
            .buttonStyle(.plain)
            .overlay {
                if path.last?.id == decision.id {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.offshootPrimary, lineWidth: 2)
                }
            }
            .accessibilityAddTraits(path.last?.id == decision.id ? .isSelected : [])
        } else {
            NavigationLink(value: decision) {
                rowView
            }
            .buttonStyle(.plain)
        }
    }
```

and in `decisionSection`, inside the `ForEach`:

```swift
                    ForEach(decisions) { decision in
                        row(decision, twoPanes: twoPanes)
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") {
                                    decisionToEdit = decision
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    decisionToDelete = decision
                                    showDeleteAlert = true
                                }
                            }
                    }
```

The corner radius 12 matches `DecisionRowView` (lines 131 and 134).

- [ ] **Step 6: Update `ContentView` for the `[Decision]` path and the Decisions pane**

In `Offshoots/ContentView.swift`:

- `@State private var decisionsPath = NavigationPath()` becomes `@State private var decisionsPath: [Decision] = []`.
- In `openDecision`, replace the three lines that build a `NavigationPath` with `decisionsPath = [target]`.
- The Decisions tab becomes:

```swift
            FoldPane(ownsWideLayout: true) { DecisionsListView(path: $decisionsPath) }
                .tag(AppTab.decisions)
                .tabItem {
                    Label("Decisions", systemImage: "checklist")
                }
```

- [ ] **Step 7: Build and run all tests**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|BUILD"
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" test 2>&1 | grep -E "error:|TEST|Executed"
```

Expected: `** BUILD SUCCEEDED **` and `** TEST SUCCEEDED **`. If `ArrangementView`'s trailing-closure form does not compile, use the labelled form `ArrangementView(primary: { … }, secondary: { … })` from the SDK declaration.

- [ ] **Step 8: Prove the iPhone 18 Pro Decisions tab is unchanged**

Repeat Task 3 Step 1 for the Decisions tab only (compare with `base-decisions.png`), then also tap one row and check that the detail still pushes and Back returns. Say "I take iPhone 18 Pro" and "I release iPhone 18 Pro".

- [ ] **Step 9: Commit**

```bash
git add Offshoots OffshootsTests
git commit -m "Show Decisions as list and detail in wide landscape

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Checkpoint 2 — Decisions on the Duo (STOP for Geoff)

**Files:** possibly `Offshoots/DecisionsSplitView.swift` (the fallback below).

- [ ] **Step 1: Install on the Duo** (same commands as Task 3 Step 2).

- [ ] **Step 2: Ask Geoff to open the Decisions tab in each landscape posture and tap a row**

Postures: partly open landscape; fully open landscape; closed; partly open portrait; fully open portrait. Read the log lines (Task 3 Step 3) and look at his DeviceHub screenshots.

Expected:
- Partly open landscape: list left, detail right, the fold between them, nothing on the fold.
- Fully open landscape: list left, detail right, no gap.
- Closed, and either portrait posture: today's single column (top half when partly open).

- [ ] **Step 3: Apply the fix that matches what Geoff sees**

- Panes stacked one above the other in landscape: change `.axes(.horizontal)` to `.axes(.vertical)` in `DecisionsSplitView`, rebuild, ask again.
- `ArrangementView` shows only one pane, or an odd gap, when fully open: use a plain split for that posture. In `DecisionsListView.layout(twoPanes:)`, branch on `posture`: keep `DecisionsSplitView` for `.folded`, and use this for `.flat`:

```swift
            HStack(spacing: 0) {
                NavigationStack { listContent(twoPanes: true) }
                    .frame(maxWidth: .infinity)
                Divider()
                DecisionsDetailPane(selection: DecisionsSelection.current(path: path, in: store.decisions))
                    .frame(maxWidth: .infinity)
            }
```

  This needs `@Environment(\.foldPosture) private var posture` in `DecisionsListView`, and the detail half of `DecisionsSplitView` moved into a `DecisionsDetailPane` view (its own file, no `#available` needed). Make that move only if this case happens, and test the move (build, run tests, look at both landscape postures).
- Anything else (for example the selection highlight is wrong, or Back appears in the detail pane): describe it to Geoff and fix it in the same branch.

- [ ] **Step 4: Commit any fix**

```bash
git add -A && git commit -m "Fix the Decisions split on the Duo

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Stop and show Geoff**

Report what changed, what he checks (the five postures above, and the delete alert in two-pane), and that Task 6 covers the sheets, rotation, reminders and docs. Wait for his go.

---

### Task 6: Checkpoint 3 — sheets, rotation, reminders, docs (STOP for Geoff)

**Files:** whatever the checks show; plus `DECISIONS.md`, `CLAUDE.md`, `TODO.md`, `CHANGELOG.md`.

- [ ] **Step 1: Check, with Geoff folding, and fix anything on the fold**

Run each in partly open portrait, partly open landscape and fully open landscape:
- Open the Edit sheet (Decisions row context menu, Edit) and the Mark Outcome sheet. Does any text or control sit on the fold? Does the sheet stay readable?
- Open the delete alert (context menu, Delete). Cancel it.
- Select a decision in two-pane landscape, then rotate to portrait: the decision must show as a pushed detail (Review Focus 4). Rotate back: the pane returns with the same decision selected.
- With a decision selected in two-pane landscape, send a reminder tap: `xcrun simctl push $D com.geoffrey.silva.Offshoots payload.json` with a `decisionID` key (see `CLAUDE.md`, "Test pushes need permission first"). The detail pane must show the tapped decision (Review Focus 5). If the permission prompt blocks the push, tell Geoff and skip this check.
- Dynamic Type: `xcrun simctl ui $D content_size accessibility-extra-extra-extra-large`, look at Decisions and Dashboard, then reset with `large`.
- Splash: `xcrun simctl spawn $D defaults delete com.geoffrey.silva.Offshoots hasSeenSplash` with the app closed, relaunch.

For each problem, fix it in this branch with a small commit. A problem that is a different chapter (for example a bug in an unrelated screen) goes into TODO.md in plain words.

- [ ] **Step 2: Run the full suite and build once more**

```bash
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination "id=$P" test 2>&1 | grep -E "error:|TEST|Executed"
```

Expected: `** TEST SUCCEEDED **`. Also confirm the scheme still has `-ReflectionUnlockOnly` disabled (`grep -n isEnabled Offshoots.xcodeproj/xcshareddata/xcschemes/Offshoots.xcscheme`; Xcode may rewrite the scheme `version`, which is not Geoff's edit).

- [ ] **Step 3: Run the doc ritual**

Use the `doc-keeper` agent: tick the TODO item "iPhone Duo: proper fold-aware layout" with today's date; add a DECISIONS entry (Offshoots now builds only with Xcode 27.1 or later, on the Mac mini; the four refinements above; the three amendable layout choices); add CHANGELOG entries under `## In Progress`; add a short note to `CLAUDE.md` (build with the 27.1 RC; the `FOLDPOSTURE` and `FOLDPANE` log lines; the posture table). Note in TODO that the same fold layout probably applies to Task(ed), Aislewise and EveryPaw only if they get a Duo "not broken" pass.

- [ ] **Step 4: Stop and show Geoff**

Report the branch state, what he checks, the results of Step 1, and what is left. Offer: merge to `main` (Claude merges locally; Geoff pushes), and delete `scratch/duo-probe` and `scratch/…` branches (only with his OK). Wait for his go.
