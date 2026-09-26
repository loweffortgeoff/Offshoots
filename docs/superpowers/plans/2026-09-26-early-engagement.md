# Early Engagement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep a new user engaged in the first weeks with review-date presets, a "So far" trend, starter suggestions, and a result line with progress copy.

**Architecture:** Pure logic goes in small `Foundation` types (`ReviewDatePreset`, `StarterSuggestion`) and in `AnalyticsEngine` (trend split, prediction gap, marked count), all unit-tested. Views get small new types (`ReviewDatePresetRow`, `StarterSuggestionsCard`, `PredictionResultBanner`) plus small edits to existing screens. The starter pre-fill passes through one `@State` value that `ContentView` owns.

**Tech Stack:** SwiftUI, Swift 6 (default actor isolation `MainActor`), Swift Testing, iOS 18.6 deployment target.

**Spec:** `docs/superpowers/specs/2026-09-26-early-engagement-design.md`

## Global Constraints

- Branch: `early-engagement`, cut from `main`. No feature commits on `main`.
- **Review stops:** stop after Task 1, Task 2, Task 3 and Task 5. Show what changed, how to check it, and what comes next. Do not start the next chunk before Geoff approves.
- Deployment target is iOS 18.6. Do not use iOS 26 or 27 APIs without an `if #available` guard. Swift has no built-in flow layout on 18.6. Use `ViewThatFits`.
- New source files go in `Offshoots/` (a synced folder, so no project edit is needed). New tests go in `OffshootsTests/`. New fixtures go in `docs/fixtures/`.
- Views import SwiftUI as `internal import SwiftUI` (project style). Logic files use `import Foundation`.
- No fixed font sizes. Use text styles. Use `@ScaledMetric` for sizes that must scale.
- Text must not truncate or break inside a word. Let it wrap.
- Every control has an accessibility label. A selected chip gets the `.isSelected` trait.
- Colors: `Color.offshootPrimary` (accent), `Color.offshootOnPrimary`, `Color.offshootBackground`, `Color.offshootCardBackground`, `.outcomeGood`, `.outcomeBad`, `.outcomeNeutral`. No new color assets.
- `ForEach` uses identity from the element (`Identifiable`), never an index.
- Leave `xcodebuild` output verbose. Do not add `-quiet`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Geoff pushes.

**Commands** (Mac mini, Xcode 27.0, iOS 27.0 simulator):

```bash
# Build
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build
# All tests
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test
# One suite
xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test -only-testing:OffshootsTests/<SuiteName>
```

A test run shuts the simulator down. Boot it again (`xcrun simctl boot <UDID>`) before `scripts/seed.sh` or `simctl install`. See `CLAUDE.md` › Simulator Testing for seeding, taps and screenshots.

---

## Chunk 1 — Review-date presets

### Task 1: Presets on Log and Edit

**Files:**
- Create: `Offshoots/ReviewDatePreset.swift`
- Create: `Offshoots/ReviewDatePresetRow.swift`
- Create: `OffshootsTests/ReviewDatePresetTests.swift`
- Modify: `Offshoots/LogDecisionView.swift` (the `followUpDate` default at line 22, the Follow-Up card at lines 158–172, the reset in `saveDecision()` at line 254)
- Modify: `Offshoots/EditDecisionView.swift` (the Follow-Up card at lines 123–141)
- Modify: `CHANGELOG.md`, `TODO.md`, `DECISIONS.md`

**Interfaces:**
- Produces: `enum ReviewDatePreset: Int, CaseIterable, Identifiable` with cases `tomorrow`, `threeDays`, `oneWeek`, `oneMonth`; `var days: Int`; `var label: String`; `func date(from now: Date = Date(), calendar: Calendar = .current) -> Date`; `static func matching(_ date: Date, from now: Date = Date(), calendar: Calendar = .current) -> ReviewDatePreset?`.
- Produces: `struct ReviewDatePresetRow: View` with `init(date: Binding<Date>)`.
- Task 3 uses `ReviewDatePreset.tomorrow.date()`.

- [ ] **Step 1: Create the branch**

```bash
git switch -c early-engagement
```

- [ ] **Step 2: Write the failing tests**

Create `OffshootsTests/ReviewDatePresetTests.swift`:

```swift
//
//  ReviewDatePresetTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReviewDatePresetTests {

    /// A fixed UTC calendar, so the tests do not depend on the machine's time zone
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static let now = ISO8601DateFormatter().date(from: "2026-09-27T15:42:00Z")!

    @Test func eachPresetAddsItsDaysAndKeepsTheTime() {
        for preset in ReviewDatePreset.allCases {
            let date = preset.date(from: Self.now, calendar: Self.calendar)
            #expect(Self.calendar.dateComponents([.day], from: Self.now, to: date).day == preset.days)
            #expect(Self.calendar.component(.hour, from: date) == 15)
            #expect(Self.calendar.component(.minute, from: date) == 42)
        }
    }

    @Test func presetDays() {
        #expect(ReviewDatePreset.allCases.map(\.days) == [1, 3, 7, 30])
    }

    @Test func matchingFindsThePresetOnTheSameDay() {
        // A calendar pick keeps its own time; only the day has to match
        let pickedOneWeekOut = Self.calendar.date(byAdding: .day, value: 7, to: Self.now)!
            .addingTimeInterval(-3 * 3600)
        #expect(ReviewDatePreset.matching(pickedOneWeekOut, from: Self.now, calendar: Self.calendar) == .oneWeek)
    }

    @Test func matchingIsNilForOtherDays() {
        let twoDaysOut = Self.calendar.date(byAdding: .day, value: 2, to: Self.now)!
        #expect(ReviewDatePreset.matching(twoDaysOut, from: Self.now, calendar: Self.calendar) == nil)
    }
}
```

- [ ] **Step 3: Run the tests and confirm they fail**

Run the one-suite command with `<SuiteName>` = `ReviewDatePresetTests`.
Expected: build failure, "cannot find 'ReviewDatePreset' in scope".

- [ ] **Step 4: Create the preset type**

Create `Offshoots/ReviewDatePreset.swift`:

```swift
//
//  ReviewDatePreset.swift
//  Offshoots
//

import Foundation

/// Quick review-date choices on Log and Edit. Each adds whole days to now and
/// keeps the time of day, so reminder timing stays as it was
enum ReviewDatePreset: Int, CaseIterable, Identifiable {
    case tomorrow = 1
    case threeDays = 3
    case oneWeek = 7
    case oneMonth = 30

    var id: Int { rawValue }

    var days: Int { rawValue }

    var label: String {
        switch self {
        case .tomorrow: return "Tomorrow"
        case .threeDays: return "3 days"
        case .oneWeek: return "1 week"
        case .oneMonth: return "1 month"
        }
    }

    func date(from now: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: now)!
    }

    /// The preset that falls on the same day as `date`, counted from `now`
    static func matching(_ date: Date, from now: Date = Date(), calendar: Calendar = .current) -> ReviewDatePreset? {
        allCases.first { calendar.isDate($0.date(from: now, calendar: calendar), inSameDayAs: date) }
    }
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run the one-suite command with `ReviewDatePresetTests`.
Expected: 4 tests pass.

- [ ] **Step 6: Create the chip row**

Create `Offshoots/ReviewDatePresetRow.swift`:

```swift
//
//  ReviewDatePresetRow.swift
//  Offshoots
//

internal import SwiftUI

/// Chips that set the review date. A chip is selected while the date falls on its day.
/// One row when it fits, two rows of two next, then a column at large text sizes
struct ReviewDatePresetRow: View {
    @Binding var date: Date

    var body: some View {
        let selected = ReviewDatePreset.matching(date)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(ReviewDatePreset.allCases) { preset in
                    ReviewDatePresetChip(preset: preset, isSelected: preset == selected) {
                        date = preset.date()
                    }
                }
            }
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    ReviewDatePresetChip(preset: .tomorrow, isSelected: selected == .tomorrow) {
                        date = ReviewDatePreset.tomorrow.date()
                    }
                    ReviewDatePresetChip(preset: .threeDays, isSelected: selected == .threeDays) {
                        date = ReviewDatePreset.threeDays.date()
                    }
                }
                GridRow {
                    ReviewDatePresetChip(preset: .oneWeek, isSelected: selected == .oneWeek) {
                        date = ReviewDatePreset.oneWeek.date()
                    }
                    ReviewDatePresetChip(preset: .oneMonth, isSelected: selected == .oneMonth) {
                        date = ReviewDatePreset.oneMonth.date()
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ReviewDatePreset.allCases) { preset in
                    ReviewDatePresetChip(preset: preset, isSelected: preset == selected) {
                        date = preset.date()
                    }
                }
            }
        }
    }
}

struct ReviewDatePresetChip: View {
    let preset: ReviewDatePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(preset.label)
                .font(.subheadline)
                .fontWeight(.medium)
                // Ideal width, so ViewThatFits moves to the next layout before a label truncates
                .fixedSize()
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .foregroundStyle(isSelected ? Color.offshootOnPrimary : Color.offshootPrimary)
                .background(
                    isSelected ? Color.offshootPrimary : Color.offshootPrimary.opacity(0.12),
                    in: Capsule()
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var date = ReviewDatePreset.tomorrow.date()
    ReviewDatePresetRow(date: $date)
        .padding()
}
```

- [ ] **Step 7: Add the row to Log Decision**

In `Offshoots/LogDecisionView.swift`:

Line 22, replace:
```swift
    @State private var followUpDate = Date().addingTimeInterval(86400)
```
with:
```swift
    @State private var followUpDate = ReviewDatePreset.tomorrow.date()
```

In the Follow-Up card, insert the row between the caption and the picker:
```swift
                            Text("When should you review this decision?")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ReviewDatePresetRow(date: $followUpDate)

                            DatePicker("Review date", selection: $followUpDate, in: earliestReviewDate..., displayedComponents: .date)
```

In `saveDecision()`, replace:
```swift
        followUpDate = Date().addingTimeInterval(86400)
```
with:
```swift
        followUpDate = ReviewDatePreset.tomorrow.date()
```

- [ ] **Step 8: Add the row to Edit Decision**

In `Offshoots/EditDecisionView.swift`, inside `if decision.actual == nil { … }`, insert the same line between the caption and the picker:
```swift
                                Text("When should you review this decision?")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                ReviewDatePresetRow(date: $followUpDate)

                                DatePicker("Review date", selection: $followUpDate, in: earliestReviewDate..., displayedComponents: .date)
```

- [ ] **Step 9: Build and run all tests**

Run the build command, then the all-tests command.
Expected: `BUILD SUCCEEDED`, then all tests pass (the existing tests plus 4 new ones).

- [ ] **Step 10: Check on the simulator**

Boot the iPhone 18 Pro, install and launch the app. Then check:
1. Log tab: "Tomorrow" is selected. Tap "1 week". The calendar moves 7 days ahead, and "1 week" is selected.
2. Tap a day on the calendar that matches no preset. No chip is selected.
3. Log a decision with "3 days". Open it, then Edit. "3 days" is selected.
4. Set text size to `accessibility-extra-extra-extra-large`. The chips move to a grid or a column, and no label truncates. Reset the size to `large`.
5. Dark mode: selected and unselected chips are readable.
6. Accessibility tree (see `CLAUDE.md`): each chip is a button, and the selected chip has `Selected`.

- [ ] **Step 11: Update the docs**

`CHANGELOG.md`: add under the newest in-flight section, in the file's style:
```markdown
- Review-date presets (Tomorrow, 3 days, 1 week, 1 month) on Log and Edit Decision. A preset keeps the time of day, so reminder timing does not change.
```

`TODO.md`: under `## Next`, add the chunk list, and check off chunk 1 in `## Done` with today's date:
```markdown
- [ ] Early engagement, chunk 2: "So far" trend (plan `docs/superpowers/plans/2026-09-26-early-engagement.md`)
- [ ] Early engagement, chunk 3: starter suggestions
- [ ] Early engagement, chunk 4: result line and progress copy
```
```markdown
- [x] Early engagement, chunk 1: review-date presets (branch `early-engagement`) — YYYY-MM-DD
```

`DECISIONS.md`: append:
```markdown
## 2026-09-26 (Review-date presets, no same-day option)
**Decision:** Log and Edit Decision get four presets: Tomorrow, 3 days, 1 week and 1 month. A preset adds whole days to now and keeps the time of day. There is no "Tonight" preset.
**Why:** Short reviews build a new user's sample fast. Readiness is day-based (`isReadyForReview` uses the start of the review day), so a same-day review would be ready as soon as it is saved. Keeping the time of day keeps reminder timing as it was.
**Alternative considered:** A "Tonight" preset with a time-of-day readiness rule. It touches readiness, Ready to Review and reminders for a small gain.
```

- [ ] **Step 12: Commit**

```bash
git add Offshoots/ReviewDatePreset.swift Offshoots/ReviewDatePresetRow.swift OffshootsTests/ReviewDatePresetTests.swift Offshoots/LogDecisionView.swift Offshoots/EditDecisionView.swift CHANGELOG.md TODO.md DECISIONS.md
git commit -m "Add review-date presets to Log and Edit Decision

Tomorrow, 3 days, 1 week and 1 month. A preset keeps the time of day,
so reminder timing does not change. Chips wrap at large text sizes.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 13: STOP — review point 1**

Show Geoff what changed, how to check it (Step 10), and that chunk 2 is next. Wait for approval.

---

## Chunk 2 — "So far" trend

### Task 2: Trend from the user's own history

**Files:**
- Modify: `Offshoots/AnalyticsEngine.swift` (`qualityTrend` at lines 68–94; add `TrendResult` beside `QualityTrend`)
- Modify: `Offshoots/QuickStatsSection.swift` (the trend tile)
- Modify: `Offshoots/QuickStatTile.swift` (optional spoken title)
- Modify: `OffshootsTests/AnalyticsEngineTests.swift`
- Create: `docs/fixtures/so-far-trend.json`
- Modify: `CLAUDE.md` (Insights fixtures note), `CHANGELOG.md`, `TODO.md`, `DECISIONS.md`

**Interfaces:**
- Produces: `struct TrendResult: Equatable { let trend: QualityTrend; let isSoFar: Bool }`.
- Changes: `AnalyticsEngine.qualityTrend(from:now:)` returns `TrendResult` (was `QualityTrend`).
- Produces: `AnalyticsEngine.minimumSoFarSample = 6`.
- Produces: `QuickStatTile` gets `var spokenTitle: String? = nil`.
- Task 5 uses `TrendResult`, `minimumSoFarSample`.

- [ ] **Step 1: Update the existing trend assertions to the new type**

In `OffshootsTests/AnalyticsEngineTests.swift`:

`trendImproves`, replace the `#expect` with:
```swift
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .improving, isSoFar: false))
```

`trendIsTooEarlyWithoutAPreviousWindow`, replace the `#expect` with (this fixture has 3 marked decisions, below the so-far minimum of 6):
```swift
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .tooEarly, isSoFar: false))
```

`emptyInput`, replace the trend line with:
```swift
        #expect(AnalyticsEngine.qualityTrend(from: [], now: Self.now).trend == .tooEarly)
```

- [ ] **Step 2: Write the failing so-far tests**

Add to `AnalyticsEngineTests`, before the closing brace:

```swift
    // MARK: - "So far" trend

    /// A marked decision resolved `daysAgo` days before `now`. Correct means an exact match
    private func marked(correct: Bool, daysAgo: Int) -> Decision {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Self.now)!
        return Decision(
            title: "Marked \(daysAgo)",
            category: .work,
            expected: .good,
            actual: correct ? .good : .veryBad,
            createdAt: date,
            resolvedAt: date,
            followUpDate: date
        )
    }

    @Test func soFarComparesOlderAndNewerHalves() {
        // All more than 60 days ago, so neither 30-day window has data
        let decisions = [
            marked(correct: false, daysAgo: 100),
            marked(correct: false, daysAgo: 99),
            marked(correct: false, daysAgo: 98),
            marked(correct: true, daysAgo: 90),
            marked(correct: true, daysAgo: 89),
            marked(correct: true, daysAgo: 88),
        ]
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .improving, isSoFar: true))
    }

    @Test func soFarSortsByResolvedDate() {
        // Same data as above, shuffled; the split follows resolved dates, not array order
        let decisions = [
            marked(correct: true, daysAgo: 88),
            marked(correct: false, daysAgo: 100),
            marked(correct: true, daysAgo: 90),
            marked(correct: false, daysAgo: 98),
            marked(correct: true, daysAgo: 89),
            marked(correct: false, daysAgo: 99),
        ]
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .improving, isSoFar: true))
    }

    @Test func soFarGivesTheOddDecisionToTheNewerHalf() {
        // Oldest first: correct, correct, correct, MISSED, correct, correct, correct.
        // Newer half gets the extra: older 3/3 = 100%, newer 3/4 = 75% → Declining.
        // (Older half with the extra would give 75% → 100%, Improving.)
        let decisions = [
            marked(correct: true, daysAgo: 100),
            marked(correct: true, daysAgo: 99),
            marked(correct: true, daysAgo: 98),
            marked(correct: false, daysAgo: 97),
            marked(correct: true, daysAgo: 96),
            marked(correct: true, daysAgo: 95),
            marked(correct: true, daysAgo: 94),
        ]
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .declining, isSoFar: true))
    }

    @Test func fiveMarkedIsTooEarly() {
        let decisions = (0..<5).map { marked(correct: true, daysAgo: 90 + $0) }
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .tooEarly, isSoFar: false))
    }

    @Test func soFarFixtureShowsImproving() throws {
        let decisions = try Fixture.load("so-far-trend")
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .improving, isSoFar: true))
    }
```

- [ ] **Step 3: Create the fixture**

Create `docs/fixtures/so-far-trend.json`. Six marked decisions resolved in July 2026 (more than 60 days before any "today" from late September on, so both 30-day windows stay empty): three older misses, three newer exact matches. One pending decision.

```json
[
  {"id": "3040b771-8114-4e1c-a799-955f79cafa18", "title": "Take the earlier train", "category": "work", "stakes": "low", "expected": "good", "actual": "bad", "createdAt": "2026-06-28T12:00:00Z", "followUpDate": "2026-07-01T12:00:00Z", "resolvedAt": "2026-07-01T12:00:00Z", "revisits": []},
  {"id": "81ce37e5-55c4-4d99-bcc6-a9d217ae63da", "title": "Cancel the streaming plan", "category": "money", "stakes": "low", "expected": "very good", "actual": "neutral", "createdAt": "2026-06-29T12:00:00Z", "followUpDate": "2026-07-02T12:00:00Z", "resolvedAt": "2026-07-02T12:00:00Z", "revisits": []},
  {"id": "098b15bd-5043-4413-8462-16b15be82d0a", "title": "Run in the morning", "category": "health", "stakes": "low", "expected": "good", "actual": "very bad", "createdAt": "2026-06-30T12:00:00Z", "followUpDate": "2026-07-03T12:00:00Z", "resolvedAt": "2026-07-03T12:00:00Z", "revisits": []},
  {"id": "95ebd9b9-4511-4b1f-8e63-766200b6054d", "title": "Call Mom on Sunday", "category": "relationships", "stakes": "medium", "expected": "good", "actual": "good", "createdAt": "2026-07-17T12:00:00Z", "followUpDate": "2026-07-20T12:00:00Z", "resolvedAt": "2026-07-20T12:00:00Z", "revisits": []},
  {"id": "95b774d5-83c6-49b0-bdfc-a2e9dfbfe7d1", "title": "Fix the leaky tap myself", "category": "home", "stakes": "low", "expected": "neutral", "actual": "neutral", "createdAt": "2026-07-18T12:00:00Z", "followUpDate": "2026-07-21T12:00:00Z", "resolvedAt": "2026-07-21T12:00:00Z", "revisits": []},
  {"id": "4d99b3a9-130b-446a-b0ba-f1c56822280c", "title": "Try the new lunch spot", "category": "other", "stakes": "low", "expected": "very good", "actual": "very good", "createdAt": "2026-07-19T12:00:00Z", "followUpDate": "2026-07-22T12:00:00Z", "resolvedAt": "2026-07-22T12:00:00Z", "revisits": []},
  {"id": "cb3e8e10-b8d3-46ba-ab87-9b4de5bf607d", "title": "Book the dentist", "category": "health", "stakes": "medium", "expected": "good", "createdAt": "2026-09-20T12:00:00Z", "followUpDate": "2026-10-10T12:00:00Z", "revisits": []}
]
```

- [ ] **Step 4: Run the tests and confirm they fail**

Run the one-suite command with `AnalyticsEngineTests`.
Expected: build failure, "cannot find 'TrendResult' in scope".

- [ ] **Step 5: Implement the trend**

In `Offshoots/AnalyticsEngine.swift`, replace the whole `qualityTrend` function and `minimumTrendSample` (lines 68–94) with:

```swift
    /// Compares prediction accuracy in the last 30 days with the 30 days before,
    /// by the date each outcome was marked. Each window needs 3 decisions.
    /// Until then, with 6 or more marked decisions, it compares the older half
    /// of them with the newer half and flags the result as "so far"
    static func qualityTrend(from decisions: [Decision], now: Date = Date()) -> TrendResult {
        let calendar = Calendar.current
        let last30Days = calendar.date(byAdding: .day, value: -30, to: now)!
        let last60Days = calendar.date(byAdding: .day, value: -60, to: now)!

        let recent = decisions.filter { ($0.resolvedDate ?? .distantPast) >= last30Days }
        let previous = decisions.filter {
            guard let date = $0.resolvedDate else { return false }
            return date >= last60Days && date < last30Days
        }

        if recent.count >= minimumTrendSample, previous.count >= minimumTrendSample {
            return TrendResult(trend: compare(newer: recent, older: previous), isSoFar: false)
        }

        let marked = decisions
            .compactMap { decision in decision.resolvedDate.map { (decision, $0) } }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
        guard marked.count >= minimumSoFarSample else {
            return TrendResult(trend: .tooEarly, isSoFar: false)
        }

        // With an odd count, the newer half gets the extra decision
        let olderCount = marked.count / 2
        let older = Array(marked.prefix(olderCount))
        let newer = Array(marked.dropFirst(olderCount))
        return TrendResult(trend: compare(newer: newer, older: older), isSoFar: true)
    }

    private static func compare(newer: [Decision], older: [Decision]) -> QualityTrend {
        let difference = accuracyBreakdown(from: newer).fraction - accuracyBreakdown(from: older).fraction

        if difference > 0.1 {
            return .improving
        } else if difference < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    static let minimumTrendSample = 3
    static let minimumSoFarSample = 6
```

Below `enum QualityTrend { … }`, add:

```swift
struct TrendResult: Equatable {
    let trend: QualityTrend
    /// True when the trend compares the older and newer halves of all marked
    /// decisions, because the 30-day windows do not have enough data yet
    let isSoFar: Bool
}
```

- [ ] **Step 6: Note the build order**

Do not run yet: `QuickStatsSection.swift` still reads a `QualityTrend` and will not build. Step 7 fixes it, and Step 8 runs the tests.

- [ ] **Step 7: Show "So far" on the Dashboard tile**

In `Offshoots/QuickStatTile.swift`, add after `var valueColor: Color = .primary`:
```swift
    /// What VoiceOver reads for the title, when the printed title has symbols
    var spokenTitle: String? = nil
```
and change the title text to:
```swift
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(spokenTitle ?? title)
```

In `Offshoots/QuickStatsSection.swift`, replace:
```swift
            let trend = AnalyticsEngine.qualityTrend(from: store.decisions)
```
with:
```swift
            let trendResult = AnalyticsEngine.qualityTrend(from: store.decisions)
            let trend = trendResult.trend
```
and replace the trend tile with:
```swift
                QuickStatTile(
                    icon: trendIcon(for: trend),
                    iconColor: trendColor(for: trend),
                    title: trendResult.isSoFar ? "Trend · So far" : "Trend",
                    value: trend.label,
                    valueColor: trendColor(for: trend),
                    spokenTitle: trendResult.isSoFar ? "Trend so far" : nil
                )
```

- [ ] **Step 8: Run all tests**

Run the all-tests command.
Expected: all tests pass, including 5 new so-far tests.

- [ ] **Step 9: Check on the simulator**

1. Boot the simulator, install the app, then `scripts/seed.sh so-far-trend`.
2. Dashboard: the trend tile title reads "Trend · So far" and the value reads "Improving". The title may wrap between words. It must not break inside a word.
3. `scripts/seed.sh insights-seed`: the tile reads "Trend" and "Improving" (the 30-day path; valid while today is 2026-09-25 to 2026-09-30).
4. `scripts/seed.sh insights-seed-too-early`: the tile reads "Too early".
5. Accessibility tree: the so-far tile reads "Trend so far, Improving".
6. Text size `accessibility-extra-extra-extra-large`: the tiles stack and the title wraps cleanly. Reset to `large`.

- [ ] **Step 10: Update the docs**

`CLAUDE.md`, in the "Insights fixtures" bullet, append:
```markdown
  `so-far-trend.json` gives Trend "So far" Improving (6 marked in July 2026,
  both 30-day windows empty), and it does not depend on today's date.
```

`CHANGELOG.md`:
```markdown
- The trend shows earlier. With 6 or more marked decisions and not enough data for the 30-day windows, the Dashboard tile compares the older half with the newer half and reads "Trend · So far".
```

`TODO.md`: move chunk 2 to Done with the date.

`DECISIONS.md`: append:
```markdown
## 2026-09-26 (Trend "So far" from the user's own history)
**Decision:** When the 30-day windows do not both have 3 marked decisions, but the user has 6 or more, the trend compares the older half of the marked decisions with the newer half, sorted by resolved date. With an odd count, the newer half gets the extra one. The Dashboard tile reads "Trend · So far". `qualityTrend` returns a `TrendResult` with an `isSoFar` flag, not a new `QualityTrend` case.
**Why:** The 30-day rule cannot show a trend before about day 31, however active the user is. With the review presets, an active user can reach 6 marked decisions in a week or two.
**Alternative considered:** An "Early read" at 2 per 30-day window (still about day 31), or a lower minimum with no label (the false signal the 2026-09-25 decision rejected). Accepted limit: at 6 decisions each half's accuracy moves in steps of a third, so Stable needs an exact match. The "So far" label covers this until the 30-day windows fill.
```

- [ ] **Step 11: Commit**

```bash
git add Offshoots/AnalyticsEngine.swift Offshoots/QuickStatsSection.swift Offshoots/QuickStatTile.swift OffshootsTests/AnalyticsEngineTests.swift docs/fixtures/so-far-trend.json CLAUDE.md CHANGELOG.md TODO.md DECISIONS.md
git commit -m "Show a \"So far\" trend before the 30-day windows fill

With 6 or more marked decisions, compare the older half with the newer
half by resolved date. qualityTrend returns TrendResult with an isSoFar
flag. Adds the so-far-trend fixture.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 12: STOP — review point 2**

Show Geoff the change, the fixture steps (Step 9), and that chunk 3 is next. Wait for approval.

---

## Chunk 3 — Starter suggestions

### Task 3: "Try a quick one" card

**Files:**
- Create: `Offshoots/StarterSuggestion.swift`
- Create: `Offshoots/StarterSuggestionsCard.swift`
- Create: `OffshootsTests/StarterSuggestionTests.swift`
- Modify: `Offshoots/ContentView.swift`
- Modify: `Offshoots/DashboardView.swift`
- Modify: `Offshoots/LogDecisionView.swift`
- Modify: `CHANGELOG.md`, `TODO.md`, `DECISIONS.md`

**Interfaces:**
- Consumes: `ReviewDatePreset.tomorrow.date()` (Task 1).
- Produces: `struct StarterSuggestion: Identifiable, Equatable { let title: String; let category: DecisionCategory }`, `static let all: [StarterSuggestion]`, `static let cutoff = 5`, `static func available(given decisions: [Decision]) -> [StarterSuggestion]`.
- Changes: `DashboardView(selectedTab:logDraft:)` and `LogDecisionView(selectedTab:draft:)` each take a new `Binding<StarterSuggestion?>`.

- [ ] **Step 1: Write the failing tests**

Create `OffshootsTests/StarterSuggestionTests.swift`:

```swift
//
//  StarterSuggestionTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct StarterSuggestionTests {

    private func logged(_ title: String) -> Decision {
        Decision(title: title, category: .other, expected: .good, followUpDate: Date())
    }

    @Test func sixExamplesOnePerCategory() {
        #expect(StarterSuggestion.all.count == 6)
        #expect(Set(StarterSuggestion.all.map(\.category)) == Set(DecisionCategory.allCases))
    }

    @Test func newUserSeesTheFirstThree() {
        #expect(StarterSuggestion.available(given: []) == Array(StarterSuggestion.all.prefix(3)))
    }

    @Test func aLoggedExampleDropsOut() {
        let first = StarterSuggestion.all[0]
        let shown = StarterSuggestion.available(given: [logged(first.title)])
        #expect(shown == Array(StarterSuggestion.all[1...3]))
    }

    @Test func otherTitlesDoNotHideExamples() {
        let shown = StarterSuggestion.available(given: [logged("Something else")])
        #expect(shown == Array(StarterSuggestion.all.prefix(3)))
    }

    @Test func noneAtTheCutoff() {
        let five = (1...StarterSuggestion.cutoff).map { logged("Decision \($0)") }
        #expect(StarterSuggestion.available(given: five).isEmpty)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run the one-suite command with `StarterSuggestionTests`.
Expected: build failure, "cannot find 'StarterSuggestion' in scope".

- [ ] **Step 3: Create the suggestion type**

Create `Offshoots/StarterSuggestion.swift`:

```swift
//
//  StarterSuggestion.swift
//  Offshoots
//

import Foundation

/// A small example decision for new users. Short reviews build a sample fast
struct StarterSuggestion: Identifiable, Equatable {
    let title: String
    let category: DecisionCategory

    var id: String { title }

    /// One per category, in the order the card offers them
    static let all: [StarterSuggestion] = [
        StarterSuggestion(title: "Reply to that email today, not Friday", category: .work),
        StarterSuggestion(title: "Buy the cheaper headphones", category: .money),
        StarterSuggestion(title: "Skip the gym and rest tonight", category: .health),
        StarterSuggestion(title: "Text an old friend first", category: .relationships),
        StarterSuggestion(title: "Leave the dishes until morning", category: .home),
        StarterSuggestion(title: "Try the new lunch spot", category: .other),
    ]

    /// The card goes away once the user has logged this many decisions
    static let cutoff = 5

    /// The first three examples whose title the user has not logged, or none at the cutoff
    static func available(given decisions: [Decision]) -> [StarterSuggestion] {
        guard decisions.count < cutoff else { return [] }
        let loggedTitles = Set(decisions.map(\.title))
        return Array(all.filter { !loggedTitles.contains($0.title) }.prefix(3))
    }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run the one-suite command with `StarterSuggestionTests`.
Expected: 5 tests pass.

- [ ] **Step 5: Create the card**

Create `Offshoots/StarterSuggestionsCard.swift`:

```swift
//
//  StarterSuggestionsCard.swift
//  Offshoots
//

internal import SwiftUI

/// Dashboard card for new users: small decisions they can review tomorrow
struct StarterSuggestionsCard: View {
    let suggestions: [StarterSuggestion]
    let onPick: (StarterSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .accessibilityHidden(true)
                    .foregroundStyle(Color.offshootPrimary)
                Text("Try a quick one")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            PrimaryCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Small decisions you can review tomorrow. Tap one to start.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 8)

                    ForEach(suggestions) { suggestion in
                        StarterSuggestionRow(title: suggestion.title) {
                            onPick(suggestion)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct StarterSuggestionRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.offshootPrimary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Fills in the Log form")
    }
}

#Preview {
    StarterSuggestionsCard(suggestions: StarterSuggestion.available(given: [])) { _ in }
        .padding()
}
```

- [ ] **Step 6: Own the draft in ContentView**

In `Offshoots/ContentView.swift`, add after `@State private var decisionsPath = NavigationPath()`:
```swift
    /// A starter suggestion on its way from the Dashboard to the Log form
    @State private var logDraft: StarterSuggestion?
```
and change the two tab views to:
```swift
            DashboardView(selectedTab: $selectedTab, logDraft: $logDraft)
```
```swift
            LogDecisionView(selectedTab: $selectedTab, draft: $logDraft)
```

- [ ] **Step 7: Show the card on the Dashboard**

In `Offshoots/DashboardView.swift`, add after `@Binding var selectedTab: AppTab`:
```swift
    @Binding var logDraft: StarterSuggestion?
```
In the `VStack(spacing: 28)`, replace:
```swift
                        ReadyToReviewSection()

                        QuickStatsSection()
```
with:
```swift
                        ReadyToReviewSection()

                        let suggestions = StarterSuggestion.available(given: store.decisions)
                        if !suggestions.isEmpty {
                            StarterSuggestionsCard(suggestions: suggestions) { suggestion in
                                logDraft = suggestion
                                selectedTab = .log
                            }
                        }

                        QuickStatsSection()
```
and update the preview:
```swift
    DashboardView(selectedTab: .constant(.dashboard), logDraft: .constant(nil))
```

- [ ] **Step 8: Apply the draft in Log Decision**

In `Offshoots/LogDecisionView.swift`, add after `@Binding var selectedTab: AppTab`:
```swift
    /// A starter suggestion to fill in; cleared once applied
    @Binding var draft: StarterSuggestion?
```
Add this modifier directly after `.navigationBarTitleDisplayMode(.inline)`:
```swift
            // initial: true covers a Log tab that did not exist yet when the suggestion was tapped
            .onChange(of: draft, initial: true) { _, suggestion in
                guard let suggestion else { return }
                title = suggestion.title
                category = suggestion.category
                followUpDate = ReviewDatePreset.tomorrow.date()
                draft = nil
            }
```
and update the preview:
```swift
    LogDecisionView(selectedTab: .constant(.log), draft: .constant(nil))
```

- [ ] **Step 9: Build and run all tests**

Run the build command, then the all-tests command.
Expected: `BUILD SUCCEEDED`; all tests pass.

- [ ] **Step 10: Check on the simulator**

1. Uninstall and reinstall the app (empty data). Wait out the 2-second splash.
2. Dashboard: "Try a quick one" shows 3 rows: the Work, Money and Health examples.
3. Tap "Buy the cheaper headphones". The Log tab opens with that title, category Money, and "Tomorrow" selected. Pick an outcome and save.
4. Back on the Dashboard: the Money example is gone, and "Text an old friend first" has taken its place.
5. Log 4 more decisions (any titles). At 5 decisions the card is gone.
6. Text size `accessibility-extra-extra-extra-large`: the rows wrap between words and the plus icon stays visible. Reset to `large`.
7. Dark mode: the card is readable.
8. Accessibility tree: each row is a button with the title as its label.

- [ ] **Step 11: Update the docs**

`CHANGELOG.md`:
```markdown
- "Try a quick one" on the Dashboard: three small example decisions for new users. A tap fills in the Log form with the title, the category and a review tomorrow. The card goes away at 5 logged decisions.
```

`TODO.md`: move chunk 3 to Done with the date.

`DECISIONS.md`: append:
```markdown
## 2026-09-26 (Starter suggestions until 5 decisions)
**Decision:** While the user has logged fewer than 5 decisions, the Dashboard shows three small example decisions, one per category, from a fixed list of six. A logged example drops out by title. A tap pre-fills the Log form through a value that `ContentView` owns. There is no dismiss control.
**Why:** A new user's first weeks are mostly waiting. Small decisions with a review tomorrow build the sample that Insights need, and show what a decision can look like.
**Alternative considered:** Suggestions on the empty Decisions list too, or a dismiss control. Both add surface for a card that goes away by itself.
```

- [ ] **Step 12: Commit**

```bash
git add Offshoots/StarterSuggestion.swift Offshoots/StarterSuggestionsCard.swift OffshootsTests/StarterSuggestionTests.swift Offshoots/ContentView.swift Offshoots/DashboardView.swift Offshoots/LogDecisionView.swift CHANGELOG.md TODO.md DECISIONS.md
git commit -m "Add starter suggestions to the Dashboard

Three small example decisions for users with fewer than 5 logged. A tap
fills in the Log form with a review tomorrow. Logged examples drop out.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 13: STOP — review point 3**

Show Geoff the change, the check steps (Step 10), and that chunk 4 is next. Wait for approval.

---

## Chunk 4 — Result line and progress copy

Tasks 4 and 5 form one review stop.

### Task 4: Result line on Decision Detail

**Files:**
- Modify: `Offshoots/AnalyticsEngine.swift`
- Create: `Offshoots/PredictionResultBanner.swift`
- Modify: `Offshoots/DecisionDetailView.swift` (the `if decision.expected == actual { … }` block at lines 221–234)
- Modify: `OffshootsTests/AnalyticsEngineTests.swift`
- Create: `OffshootsTests/PredictionResultBannerTests.swift`

**Interfaces:**
- Produces: `AnalyticsEngine.predictionGap(for decision: Decision) -> Int?` (first rating minus expected; positive = better than expected; nil until marked).
- Produces: `AnalyticsEngine.markedCount(from decisions: [Decision]) -> Int`.
- Produces: `struct PredictionResultBanner: View { let gap: Int; let markedCount: Int }` with `static func message(for gap: Int) -> String` and `static func unlockText(markedCount: Int) -> String?`.
- Task 5 uses `markedCount(from:)`.

- [ ] **Step 1: Write the failing engine tests**

Add to `AnalyticsEngineTests`, before the closing brace:

```swift
    // MARK: - Prediction gap and marked count

    @Test func predictionGapIsNilUntilMarked() {
        let pending = Decision(title: "P", category: .work, expected: .good, followUpDate: Self.now)
        #expect(AnalyticsEngine.predictionGap(for: pending) == nil)
    }

    @Test(arguments: [
        (DecisionOutcome.good, DecisionOutcome.good, 0),
        (.good, .veryGood, 1),
        (.good, .neutral, -1),
        (.bad, .veryGood, 3),
        (.veryGood, .veryBad, -4),
    ])
    func predictionGapIsFirstRatingMinusExpected(expected: DecisionOutcome, actual: DecisionOutcome, gap: Int) {
        let decision = Decision(title: "M", category: .work, expected: expected, actual: actual, followUpDate: Self.now)
        #expect(AnalyticsEngine.predictionGap(for: decision) == gap)
    }

    @Test func predictionGapIgnoresRevisits() {
        let decision = Decision(
            title: "R", category: .work, expected: .good, actual: .bad, followUpDate: Self.now,
            revisits: [Revisit(outcome: .veryGood)]
        )
        #expect(AnalyticsEngine.predictionGap(for: decision) == -2)
    }

    @Test func markedCountCountsFirstRatings() throws {
        #expect(AnalyticsEngine.markedCount(from: try Fixture.load("insights-seed-too-early")) == 3)
        #expect(AnalyticsEngine.markedCount(from: []) == 0)
    }
```

If the parameterized test does not compile under `MainActor` default isolation (the arguments must be `Sendable`), replace it with one test that loops over the same five tuples.

- [ ] **Step 2: Write the failing banner tests**

Create `OffshootsTests/PredictionResultBannerTests.swift`:

```swift
//
//  PredictionResultBannerTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct PredictionResultBannerTests {

    @Test func messages() {
        #expect(PredictionResultBanner.message(for: 0) == "You predicted correctly!")
        #expect(PredictionResultBanner.message(for: 1) == "Close. It went a little better than you expected.")
        #expect(PredictionResultBanner.message(for: -1) == "Close. It went a little worse than you expected.")
        #expect(PredictionResultBanner.message(for: 2) == "It went better than you expected.")
        #expect(PredictionResultBanner.message(for: -4) == "It went worse than you expected.")
    }

    @Test func unlockText() {
        #expect(PredictionResultBanner.unlockText(markedCount: 1) == "1 of 3 marked · Optimism unlocks at 3")
        #expect(PredictionResultBanner.unlockText(markedCount: 2) == "2 of 3 marked · Optimism unlocks at 3")
        #expect(PredictionResultBanner.unlockText(markedCount: 3) == "3 of 6 marked · Trend unlocks at 6")
        #expect(PredictionResultBanner.unlockText(markedCount: 5) == "5 of 6 marked · Trend unlocks at 6")
        #expect(PredictionResultBanner.unlockText(markedCount: 6) == nil)
    }
}
```

- [ ] **Step 3: Run the tests and confirm they fail**

Run the all-tests command.
Expected: build failure, "type 'AnalyticsEngine' has no member 'predictionGap'" and "cannot find 'PredictionResultBanner' in scope".

- [ ] **Step 4: Add the engine helpers**

In `Offshoots/AnalyticsEngine.swift`, add after `predictionAccuracy(from:)`:

```swift
    /// Steps from the prediction to the first rating. Positive means it went
    /// better than expected. Nil until an outcome is marked
    static func predictionGap(for decision: Decision) -> Int? {
        decision.actual.map { $0.numericValue - decision.expected.numericValue }
    }

    /// Decisions with a first rating
    static func markedCount(from decisions: [Decision]) -> Int {
        decisions.filter { $0.actual != nil }.count
    }
```

- [ ] **Step 5: Create the banner**

Create `Offshoots/PredictionResultBanner.swift`:

```swift
//
//  PredictionResultBanner.swift
//  Offshoots
//

internal import SwiftUI

/// How the first rating compared with the prediction, and what unlocks next
struct PredictionResultBanner: View {
    /// First rating minus expected, in steps
    let gap: Int
    /// Marked decisions across the whole store, this one included
    let markedCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                    .foregroundStyle(gap == 0 ? Color.yellow : Color.offshootPrimary)
                Text(Self.message(for: gap))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.offshootPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let unlock = Self.unlockText(markedCount: markedCount) {
                Text(unlock)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(gap == 0 ? Color.yellow.opacity(0.1) : Color.offshootBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        if gap == 0 { return "trophy.fill" }
        return gap > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    static func message(for gap: Int) -> String {
        switch gap {
        case 0: return "You predicted correctly!"
        case 1: return "Close. It went a little better than you expected."
        case -1: return "Close. It went a little worse than you expected."
        case let steps where steps > 1: return "It went better than you expected."
        default: return "It went worse than you expected."
        }
    }

    static func unlockText(markedCount: Int) -> String? {
        if markedCount < AnalyticsEngine.minimumBiasSample {
            return "\(markedCount) of \(AnalyticsEngine.minimumBiasSample) marked · Optimism unlocks at \(AnalyticsEngine.minimumBiasSample)"
        }
        if markedCount < AnalyticsEngine.minimumSoFarSample {
            return "\(markedCount) of \(AnalyticsEngine.minimumSoFarSample) marked · Trend unlocks at \(AnalyticsEngine.minimumSoFarSample)"
        }
        return nil
    }
}

#Preview {
    VStack {
        PredictionResultBanner(gap: 0, markedCount: 1)
        PredictionResultBanner(gap: 1, markedCount: 4)
        PredictionResultBanner(gap: -3, markedCount: 8)
    }
    .padding()
}
```

- [ ] **Step 6: Use the banner on Decision Detail**

In `Offshoots/DecisionDetailView.swift`, replace the whole block:
```swift
                                if decision.expected == actual {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trophy.fill")
                                            .accessibilityHidden(true)
                                            .foregroundStyle(.yellow)
                                        Text("You predicted correctly!")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.offshootPrimary)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(12)
                                }
```
with:
```swift
                                if let gap = AnalyticsEngine.predictionGap(for: decision) {
                                    PredictionResultBanner(
                                        gap: gap,
                                        markedCount: AnalyticsEngine.markedCount(from: store.decisions)
                                    )
                                }
```

If `actual` is now unused in that `if let actual` block, leave the binding: the block still uses `actual` for the icon and label above.

- [ ] **Step 7: Run all tests**

Run the all-tests command.
Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add Offshoots/AnalyticsEngine.swift Offshoots/PredictionResultBanner.swift Offshoots/DecisionDetailView.swift OffshootsTests/AnalyticsEngineTests.swift OffshootsTests/PredictionResultBannerTests.swift
git commit -m "Show a result line for every marked decision

Decision Detail compares the first rating with the prediction and, while
fewer than 6 decisions are marked, says what unlocks next.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: Progress copy on the Dashboard and Insights

**Files:**
- Modify: `Offshoots/QuickStatsSection.swift` (the trend tile value)
- Modify: `Offshoots/OptimismCard.swift` (add `markedCount`, new empty text)
- Modify: `Offshoots/AnalyticsView.swift:51` (pass `markedCount`)
- Modify: `Offshoots/PredictionAccuracyCard.swift:32`, `Offshoots/OutcomeDistributionCard.swift:32`, `Offshoots/OutcomeTrendCard.swift:61`
- Modify: `README.md`, `CHANGELOG.md`, `TODO.md`, `DECISIONS.md`

**Interfaces:**
- Consumes: `AnalyticsEngine.markedCount(from:)` (Task 4), `TrendResult`, `minimumSoFarSample` (Task 2).
- Changes: `OptimismCard(bias:markedCount:)`.

- [ ] **Step 1: Trend tile shows progress in place of "Too early"**

In `Offshoots/QuickStatsSection.swift`, in the trend tile, replace:
```swift
                    value: trend.label,
```
with:
```swift
                    value: trend == .tooEarly
                        ? "\(AnalyticsEngine.markedCount(from: store.decisions)) of \(AnalyticsEngine.minimumSoFarSample) marked"
                        : trend.label,
```

- [ ] **Step 2: Optimism card shows progress**

In `Offshoots/OptimismCard.swift`, add after `let bias: OptimismBias?`:
```swift
    /// Marked decisions so far, for the progress text before the card unlocks
    let markedCount: Int
```
and replace the `else` text:
```swift
                Text("Mark \(AnalyticsEngine.minimumBiasSample) outcomes to see whether you tend to expect too much or too little.")
```
with:
```swift
                let remaining = AnalyticsEngine.minimumBiasSample - markedCount
                Text("\(markedCount) of \(AnalyticsEngine.minimumBiasSample) marked. Mark \(remaining) more to see whether you tend to expect too much or too little.")
```

In `Offshoots/AnalyticsView.swift`, replace:
```swift
                            OptimismCard(bias: AnalyticsEngine.optimismBias(from: store.decisions))
```
with:
```swift
                            OptimismCard(
                                bias: AnalyticsEngine.optimismBias(from: store.decisions),
                                markedCount: AnalyticsEngine.markedCount(from: store.decisions)
                            )
```

- [ ] **Step 3: Empty cards point to the next action**

`Offshoots/PredictionAccuracyCard.swift`, replace `Text("No completed decisions to analyze")` with:
```swift
                Text("Mark your first outcome to see this.")
```

`Offshoots/OutcomeDistributionCard.swift`, replace `Text("No completed decisions yet")` with:
```swift
                Text("Mark your first outcome to see this.")
```

`Offshoots/OutcomeTrendCard.swift`: this card is empty either when nothing is marked or when nothing was marked in the last 8 weeks, so it needs both texts. Replace `Text("No completed decisions to show trends")` with:
```swift
                Text(decisions.contains { $0.actual != nil }
                     ? "No outcomes marked in the last 8 weeks."
                     : "Mark your first outcome to see this.")
```

- [ ] **Step 4: Build and run all tests**

Run the build command, then the all-tests command.
Expected: `BUILD SUCCEEDED`; all tests pass.

- [ ] **Step 5: Check on the simulator (chunk 4)**

1. Fresh install (empty data). Log a decision expecting Good with "Tomorrow".
2. Insights: Prediction Accuracy and Outcomes read "Mark your first outcome to see this." Optimism reads "0 of 3 marked. Mark 3 more…". The Dashboard trend tile reads "0 of 6 marked".
3. `scripts/seed.sh insights-seed-too-early` (3 marked). Dashboard trend tile: "3 of 6 marked". Optimism shows a result.
4. Open "R1 correct recent": the banner reads "You predicted correctly!" with the trophy, and "3 of 6 marked · Trend unlocks at 6".
5. Open "Pending home" (expected Good). Tap Mark Outcome and pick Great. The banner reads "Close. It went a little better than you expected." and "4 of 6 marked · Trend unlocks at 6".
6. `scripts/seed.sh so-far-trend`. Open "Run in the morning" (expected Good, got Very Bad): "It went worse than you expected." with no unlock line.
7. Outcome Trends with `so-far-trend` (all outcomes in July): "No outcomes marked in the last 8 weeks."
8. Text size `accessibility-extra-extra-extra-large`: the banner and tiles wrap between words. Reset to `large`. Dark mode: the banner is readable.
9. Accessibility tree: the banner reads as one element with both lines.

- [ ] **Step 6: Update the docs**

`README.md`, in `## Features`, add after "Follow-Up Reminders":
```markdown
- **Review Presets** — Tomorrow, 3 days, 1 week or 1 month, one tap on Log and Edit
- **Starter Suggestions** — Small example decisions for your first few entries
```
and in `### Analytics & Insights`, replace the Trend line with:
```markdown
- **Trend** — Whether your accuracy is Improving, Declining or Stable over the last 30 days (first rating). Before that, from 6 marked decisions, a "So far" trend compares your older and newer decisions
```
and in `### Revisits` or near Reflection Notes, add:
```markdown
- **Result Line** — Each marked decision says how the result compared with your prediction, and what unlocks next
```

`CHANGELOG.md`:
```markdown
- Decision Detail shows how the first rating compared with the prediction for every marked decision, and what unlocks next while fewer than 6 are marked.
- Progress in place of empty states: the trend tile reads "N of 6 marked", the Optimism card counts toward 3, and empty Insights cards say "Mark your first outcome to see this."
```

`TODO.md`: move chunk 4 to Done with the date. Add under `## Next`:
```markdown
- [ ] Merge `early-engagement` to `main` after Geoff's simulator check.
```

`DECISIONS.md`: append:
```markdown
## 2026-09-26 (Result line and progress copy)
**Decision:** Every marked decision shows a result line on Decision Detail, measured against the first rating (exact, one step better or worse, or more). While fewer than 6 decisions are marked, a second line says what unlocks next. The trend tile shows "N of 6 marked" in place of "Too early", and empty Insights cards say "Mark your first outcome to see this."
**Why:** The first marked outcome gave nothing back unless the guess was exact, and "Too early" did not say what to do. The first rating is the same basis that accuracy uses.
**Alternative considered:** A short overlay after Save in Mark Outcome. It disappears, and VoiceOver users can miss it.
```

- [ ] **Step 7: Commit**

```bash
git add Offshoots/QuickStatsSection.swift Offshoots/OptimismCard.swift Offshoots/AnalyticsView.swift Offshoots/PredictionAccuracyCard.swift Offshoots/OutcomeDistributionCard.swift Offshoots/OutcomeTrendCard.swift README.md CHANGELOG.md TODO.md DECISIONS.md
git commit -m "Show progress in place of empty Insights states

The trend tile reads \"N of 6 marked\", Optimism counts toward 3, and
empty cards point to marking the first outcome.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 8: STOP — review point 4**

Show Geoff chunk 4 (Tasks 4 and 5), the check steps (Task 5 Step 5), and suggest a code review of the whole branch before the merge. Wait for approval.
