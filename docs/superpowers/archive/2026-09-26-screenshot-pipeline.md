# Screenshot Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One command gives a seeded, dark, 9:41 Offshoots on the 6.9" simulator, so the 7 App Store shots come out clean and consistent. Fix the two app problems that the shots show.

**Architecture:** A JSON fixture anchored to 2026-09-27 is date-shifted to today by `scripts/screenshots.sh` and copied in as the store file. No screenshot code ships in the app. A unit test pins every number the shots show. The Outcomes percentages move into `AnalyticsEngine` and use the largest remainder method.

**Tech Stack:** SwiftUI, Swift Testing, zsh, `xcrun simctl`, `python3` (3.9, system).

**Spec:** `docs/superpowers/specs/2026-09-26-screenshot-pipeline-design.md`

## Global Constraints

- Branch `screenshot-pipeline`. Never commit code to `main`. Claude commits; Geoff pushes.
- Three review stops: after Task 2, after Task 4, after Task 5. Stop at each one. Do not chain the next task.
- No screenshot code in the app target. No `ScreenshotSeed`, no `-screenshots` argument.
- Do not change `scripts/seed.sh`.
- Dark appearance only. Device: iPhone 18 Pro Max, iOS 27.0 (Mac mini).
- Fixture anchor: **2026-09-27**. All fixture times are `12:00:00Z`.
- Captures go to `~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/<YYYY-MM-DD>/`.
- Optimism copy (better): "On average, you expect {n} steps better than the outcome you first mark, across {count} decisions."
- Optimism copy (worse): "On average, you expect {n} steps worse than the outcome you first mark, across {count} decisions."
- Leave `xcodebuild` output verbose. Do not add `-quiet`.
- Build: `xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'generic/platform=iOS Simulator' build`
- Test: `xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test`
- A test run shuts the iPhone 18 Pro simulator down. Boot it again before `seed.sh`.

---

## Stop 1 — App fixes

### Task 1: Outcome percentages add up to 100

**Files:**
- Modify: `Offshoots/AnalyticsEngine.swift` (add `outcomeDistribution(from:)` after `goodOutcomePercentage`; add `OutcomeShare` after `AccuracyBreakdown`)
- Modify: `Offshoots/OutcomeDistributionCard.swift:15-21` and `:43-66`
- Test: `OffshootsTests/AnalyticsEngineTests.swift` (Edge cases section)
- Modify: `CHANGELOG.md`, `DECISIONS.md`

**Interfaces:**
- Produces: `AnalyticsEngine.outcomeDistribution(from decisions: [Decision]) -> [OutcomeShare]` and `struct OutcomeShare: Equatable { let outcome: DecisionOutcome; let count: Int; let percent: Int }`. Rows are in `DecisionOutcome.allCases` order, only outcomes with a count above 0, grouped by `currentOutcome` of marked decisions. Task 3 uses this.

- [ ] **Step 1: Create the branch**

```bash
git checkout -b screenshot-pipeline
```

- [ ] **Step 2: Write the failing tests**

Add to the `// MARK: - Edge cases` section of `OffshootsTests/AnalyticsEngineTests.swift`. Add this helper at the end of the struct:

```swift
    /// One marked decision per outcome in `latest`, rated once
    private func marked(_ latest: [DecisionOutcome]) -> [Decision] {
        latest.map { outcome in
            Decision(title: "Test", category: .other, expected: .neutral, actual: outcome, followUpDate: Self.now)
        }
    }
```

And these tests:

```swift
    @Test func outcomePercentagesAddUpTo100() {
        // The 2026-09-26 captures: truncation showed 16 / 16 / 33 / 16 / 16 = 97
        let decisions = marked([.veryBad, .bad, .neutral, .neutral, .good, .veryGood])
        let shares = AnalyticsEngine.outcomeDistribution(from: decisions)
        #expect(shares.map(\.outcome) == [.veryBad, .bad, .neutral, .good, .veryGood])
        #expect(shares.map(\.count) == [1, 1, 2, 1, 1])
        // Ties in the remainder go in outcome order, Very Bad first
        #expect(shares.map(\.percent) == [17, 17, 33, 17, 16])
    }

    @Test func outcomePercentagesEvenSplit() {
        let shares = AnalyticsEngine.outcomeDistribution(from: marked(DecisionOutcome.allCases))
        #expect(shares.map(\.percent) == [20, 20, 20, 20, 20])
    }

    @Test func outcomePercentagesSkipEmptyOutcomes() {
        let shares = AnalyticsEngine.outcomeDistribution(from: marked([.good, .good, .veryBad]))
        #expect(shares.map(\.outcome) == [.veryBad, .good])
        #expect(shares.map(\.percent) == [33, 67])
    }

    @Test func outcomePercentagesUseLatestRating() {
        var decision = Decision(title: "Test", category: .other, expected: .neutral, actual: .bad, followUpDate: Self.now)
        decision.revisits = [Revisit(date: Self.now, outcome: .good)]
        let pending = Decision(title: "Pending", category: .other, expected: .good, followUpDate: Self.now)
        let shares = AnalyticsEngine.outcomeDistribution(from: [decision, pending])
        #expect(shares == [OutcomeShare(outcome: .good, count: 1, percent: 100)])
    }

    @Test func outcomePercentagesEmpty() {
        #expect(AnalyticsEngine.outcomeDistribution(from: []).isEmpty)
    }
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -only-testing:OffshootsTests/AnalyticsEngineTests test`
Expected: build failure, "type 'AnalyticsEngine' has no member 'outcomeDistribution'".

- [ ] **Step 4: Implement**

In `Offshoots/AnalyticsEngine.swift`, after `goodOutcomePercentage(from:)`:

```swift
    /// Latest ratings of marked decisions, per outcome, with whole percentages
    /// that always add up to 100 (largest remainder). Ties in the remainder go
    /// in outcome order, so the result is stable
    static func outcomeDistribution(from decisions: [Decision]) -> [OutcomeShare] {
        let latest = decisions.compactMap { $0.actual == nil ? nil : $0.currentOutcome }
        guard !latest.isEmpty else { return [] }

        let total = latest.count
        let counts = DecisionOutcome.allCases.compactMap { outcome -> (DecisionOutcome, Int)? in
            let count = latest.filter { $0 == outcome }.count
            return count > 0 ? (outcome, count) : nil
        }

        var percents = counts.map { $0.1 * 100 / total }
        let remainders = counts.map { $0.1 * 100 % total }
        let leftover = 100 - percents.reduce(0, +)
        let order = remainders.indices.sorted { remainders[$0] > remainders[$1] || (remainders[$0] == remainders[$1] && $0 < $1) }
        for index in order.prefix(leftover) {
            percents[index] += 1
        }

        return counts.indices.map { OutcomeShare(outcome: counts[$0].0, count: counts[$0].1, percent: percents[$0]) }
    }
```

After `struct AccuracyBreakdown { … }`:

```swift
struct OutcomeShare: Equatable {
    let outcome: DecisionOutcome
    let count: Int
    let percent: Int
}
```

- [ ] **Step 5: Use it in the card**

In `Offshoots/OutcomeDistributionCard.swift`, delete the `outcomeData` property (lines 15–21). In `body`, inside the `else` branch, before `let layout = …`, add:

```swift
                let shares = AnalyticsEngine.outcomeDistribution(from: decisions)
```

Change `Chart(outcomeData, id: \.outcome)` to `Chart(shares, id: \.outcome)` and `ForEach(outcomeData, id: \.outcome)` to `ForEach(shares, id: \.outcome)`. Change the legend text:

```swift
                                Text("\(item.percent)%")
```

Keep `totalCompleted` (the empty state uses it).

- [ ] **Step 6: Run the tests to verify they pass**

Run the Step 3 command. Expected: all `AnalyticsEngineTests` pass.

- [ ] **Step 7: Docs**

`CHANGELOG.md`: add a section above `## Merged to main — branch early-engagement`:

```markdown
## In progress — branch `screenshot-pipeline`

### 2026-09-26 — Screenshot pipeline, stop 1
- The Outcomes legend on Insights always adds up to 100%. It used to cut off the decimals, so it could show 97%.
```

`DECISIONS.md`: append:

```markdown
## 2026-09-26 (Outcome percentages use the largest remainder)
**Decision:** The Outcomes legend rounds with the largest remainder method, so the shown percentages always add up to 100. Ties go in outcome order, Very Bad first. The calculation lives in `AnalyticsEngine.outcomeDistribution(from:)`.
**Why:** The legend truncated, so 6 decisions showed 16 + 16 + 33 + 16 + 16 = 97%. A legend that does not add up to 100 looks broken, in the app and in App Store screenshots.
**Alternative considered:** Plain `.rounded()`, as the rest of the app does. Simpler, but the same data shows 101%.
```

- [ ] **Step 8: Commit**

```bash
git add Offshoots/AnalyticsEngine.swift Offshoots/OutcomeDistributionCard.swift OffshootsTests/AnalyticsEngineTests.swift CHANGELOG.md DECISIONS.md
git commit -m "Outcome percentages add up to 100

Move the Outcomes legend math into AnalyticsEngine.outcomeDistribution
and use the largest remainder method. Truncation showed 97% for the
2026-09-26 capture data.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: Optimism copy

**Files:**
- Modify: `Offshoots/OptimismCard.swift:80-89` (`detail(for:)`)
- Modify: `CHANGELOG.md`, `DECISIONS.md`

**Interfaces:** none.

This is view copy. There is no unit test; check it on the simulator.

- [ ] **Step 1: Check for tests that quote the old text**

Run: `grep -rn "first result" Offshoots OffshootsTests`
Expected: only `Offshoots/OptimismCard.swift`. If a test quotes it, update that test in Step 2.

- [ ] **Step 2: Change the copy**

Replace the body of `detail(for:)`'s `switch`:

```swift
        switch bias.lean {
        case .optimistic:
            return "On average, you expect \(steps) steps better than the outcome you first mark, across \(bias.sample) decisions."
        case .pessimistic:
            return "On average, you expect \(steps) steps worse than the outcome you first mark, across \(bias.sample) decisions."
        case .calibrated:
            return "On average, your predictions match the outcome you first mark, across \(bias.sample) decisions."
        }
```

The calibrated line is not in the spec. It changes only "the first result" to "the outcome you first mark", so the three lines match. Tell Geoff at the stop.

- [ ] **Step 3: Build and test**

Run the Global Constraints test command. Expected: all tests pass.

- [ ] **Step 4: Check on the simulator**

```bash
xcrun simctl boot 204520A6-E5B5-447D-8A6B-028317014DD8 || true
```

Build and install the app on the iPhone 18 Pro (Xcode Run, or `xcodebuild … -destination 'id=204520A6-E5B5-447D-8A6B-028317014DD8' build` and `simctl install`). Then run `scripts/seed.sh insights-seed`. Open Insights. Check:
- The Optimism card reads "On average, you expect 0.5 steps better than the outcome you first mark, across 6 decisions."
- The Outcomes legend adds up to 100.

Take a screenshot with `xcrun simctl io 204520A6-E5B5-447D-8A6B-028317014DD8 screenshot <scratchpad>/stop1-insights.png` for Geoff.

- [ ] **Step 5: Docs**

`CHANGELOG.md`, under the stop 1 heading:

```markdown
- The Optimism card reads "On average, you expect 0.5 steps better than the outcome you first mark, across 6 decisions." It used to say "than the first result".
```

`DECISIONS.md`:

```markdown
## 2026-09-26 (Optimism wording)
**Decision:** "On average, you expect {n} steps better (or worse) than the outcome you first mark, across {count} decisions." The calibrated line uses the same "outcome you first mark".
**Why:** "Than the first result" did not make sense without context, for example in an App Store screenshot. The new line still says that the bias is measured against the first rating.
**Alternative considered:** "You tend to expect better than you get: 1.2 steps on average." Easier to read, but it drops the first-rating detail.
```

- [ ] **Step 6: Commit**

```bash
git add Offshoots/OptimismCard.swift CHANGELOG.md DECISIONS.md
git commit -m "Clearer Optimism wording

Say what the steps are measured against: the outcome you first mark.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: STOP 1.** Show Geoff the diff, the test result, and the Insights screenshot. Wait for approval.

---

## Stop 2 — Fixture and script

### Task 3: Screenshot fixture and its test

**Files:**
- Create: `docs/fixtures/screenshots.json`
- Create: `OffshootsTests/ScreenshotFixtureTests.swift`

**Interfaces:**
- Consumes: `AnalyticsEngine.outcomeDistribution(from:)` and `OutcomeShare` (Task 1); `Fixture.load(_:)` (`OffshootsTests/Fixture.swift`).
- Produces: `docs/fixtures/screenshots.json`, which Task 4's script shifts and loads.

`docs/fixtures/` is a synced group in `OffshootsTests`. A new file needs no project change.

**The data** (now = 2026-09-27; "previous" window = 2026-07-29 to 2026-08-28, "recent" = from 2026-08-28):

| Title | Category | Expected | First | Latest | Marked | Note |
|---|---|---|---|---|---|---|
| Replace the old couch | home | good | — | — | pending, due 10-08 | high stakes |
| Book the dentist | health | good | — | — | pending, due 10-02 | |
| Tell Sam the truth about the trip | relationships | very good | very good | very good | 09-24 | recent, correct |
| Try the new lunch spot | other | bad | bad | bad | 09-20 | recent, correct |
| Skip the new phone this year | money | good | good | good | 09-16 | recent, correct |
| Turn down the side project | work | neutral | neutral | neutral | 09-11 | recent, correct |
| Plan a weekend with my sister | relationships | very good | very good | very good | 09-06 | recent, correct |
| Ask for a four-day week | work | good | good | good | 09-01 | recent, correct, **revisit due 09-27** |
| Repaint the hallway myself | home | neutral | very bad | very bad | 08-24 | previous, missed |
| Sign up for the 10K | health | good | neutral | neutral | 08-19 | previous, close |
| Switch to the cheaper phone plan | money | good | good | good | 08-15 | previous, correct |
| Say yes to leading the offsite | work | good | bad | **good** | 08-12 | previous, missed; revisits Neutral 08-26, Good 09-18 |

Results: 12 total, 2 pending, 10 marked. Latest 1 / 1 / 2 / 4 / 2 → 10 / 10 / 20 / 40 / 20%, 60% good. Accuracy 7 correct, 1 close, 2 missed = 70%. Recent 6/6, previous 1/4 → Improving. Optimism (2 + 0 + 1 + 2) / 10 = 0.5 steps, optimistic. Top category Work (3). All marked dates are inside the last 8 weeks. The file is newest first, so Dashboard "Recent" shows the couch, the dentist and the trip.

- [ ] **Step 1: Write the fixture**

Create `docs/fixtures/screenshots.json`:

```json
[
  {"id": "7d7893ca-412e-49b9-b82c-a8fc2d740aa9", "title": "Replace the old couch", "category": "home", "stakes": "high", "expected": "good", "notes": "The springs are gone. Spending more now should mean ten good years.", "createdAt": "2026-09-26T12:00:00Z", "followUpDate": "2026-10-08T12:00:00Z", "revisits": []},
  {"id": "9fddbe26-3059-456d-96ec-c2b245837ca2", "title": "Book the dentist", "category": "health", "stakes": "low", "expected": "good", "createdAt": "2026-09-25T12:00:00Z", "followUpDate": "2026-10-02T12:00:00Z", "revisits": []},
  {"id": "afafee2d-33e7-411e-aee8-b22ac86c8dd2", "title": "Tell Sam the truth about the trip", "category": "relationships", "stakes": "high", "expected": "very good", "actual": "very good", "notes": "Hard conversation, but keeping it in is worse.", "reflection": "Glad I said it. We are closer now.", "createdAt": "2026-09-21T12:00:00Z", "followUpDate": "2026-09-24T12:00:00Z", "resolvedAt": "2026-09-24T12:00:00Z", "revisits": []},
  {"id": "ae26845c-4069-47b5-a9e0-d4e8942ad274", "title": "Try the new lunch spot", "category": "other", "stakes": "low", "expected": "bad", "actual": "bad", "createdAt": "2026-09-17T12:00:00Z", "followUpDate": "2026-09-20T12:00:00Z", "resolvedAt": "2026-09-20T12:00:00Z", "revisits": []},
  {"id": "3af38814-9f3e-4a87-9491-8cdb757ef619", "title": "Skip the new phone this year", "category": "money", "stakes": "medium", "expected": "good", "actual": "good", "createdAt": "2026-09-13T12:00:00Z", "followUpDate": "2026-09-16T12:00:00Z", "resolvedAt": "2026-09-16T12:00:00Z", "revisits": []},
  {"id": "feb7a1c6-1fad-41db-9596-717916163081", "title": "Turn down the side project", "category": "work", "stakes": "medium", "expected": "neutral", "actual": "neutral", "createdAt": "2026-09-08T12:00:00Z", "followUpDate": "2026-09-11T12:00:00Z", "resolvedAt": "2026-09-11T12:00:00Z", "revisits": []},
  {"id": "79891681-7e7c-4306-9fc1-456ff2a5ba3c", "title": "Plan a weekend with my sister", "category": "relationships", "stakes": "medium", "expected": "very good", "actual": "very good", "createdAt": "2026-09-03T12:00:00Z", "followUpDate": "2026-09-06T12:00:00Z", "resolvedAt": "2026-09-06T12:00:00Z", "revisits": []},
  {"id": "8ba7fc2d-1aae-46f7-9f8e-d6fc89dfad25", "title": "Ask for a four-day week", "category": "work", "stakes": "high", "expected": "good", "actual": "good", "notes": "Same work, fewer meetings. Worst case, they say no.", "createdAt": "2026-08-25T12:00:00Z", "followUpDate": "2026-09-01T12:00:00Z", "resolvedAt": "2026-09-01T12:00:00Z", "secondaryFollowUpDate": "2026-09-27T12:00:00Z", "revisits": []},
  {"id": "2ae5cc71-26f7-4db7-8c27-26404c2e67e6", "title": "Repaint the hallway myself", "category": "home", "stakes": "low", "expected": "neutral", "actual": "very bad", "reflection": "Two weekends and it still looks patchy. Next time, hire someone.", "createdAt": "2026-08-20T12:00:00Z", "followUpDate": "2026-08-24T12:00:00Z", "resolvedAt": "2026-08-24T12:00:00Z", "revisits": []},
  {"id": "c4aeecd1-dde4-4dee-9fe3-a5f061fcb92f", "title": "Sign up for the 10K", "category": "health", "stakes": "medium", "expected": "good", "actual": "neutral", "createdAt": "2026-08-16T12:00:00Z", "followUpDate": "2026-08-19T12:00:00Z", "resolvedAt": "2026-08-19T12:00:00Z", "revisits": []},
  {"id": "ab6c26a8-5e5c-4b3a-be52-e679c6098432", "title": "Switch to the cheaper phone plan", "category": "money", "stakes": "low", "expected": "good", "actual": "good", "createdAt": "2026-08-12T12:00:00Z", "followUpDate": "2026-08-15T12:00:00Z", "resolvedAt": "2026-08-15T12:00:00Z", "revisits": []},
  {"id": "8f9499b1-abcb-4c75-9a91-f19215bc9d6b", "title": "Say yes to leading the offsite", "category": "work", "stakes": "high", "expected": "good", "actual": "bad", "notes": "Nervous about presenting, but it is a chance to be seen.", "reflection": "Too much prep on top of my normal work.", "createdAt": "2026-08-08T12:00:00Z", "followUpDate": "2026-08-12T12:00:00Z", "resolvedAt": "2026-08-12T12:00:00Z", "secondaryFollowUpDate": "2026-10-18T12:00:00Z", "revisits": [
    {"id": "b1d30f09-1ad3-4c60-a43f-feb7f7fd4cd2", "date": "2026-08-26T12:00:00Z", "outcome": "neutral", "note": "The team liked it. The stress is fading."},
    {"id": "416b3f20-aa4f-4596-b6b5-813099d24ca8", "date": "2026-09-18T12:00:00Z", "outcome": "good", "note": "Two new projects came out of it."}
  ]}
]
```

- [ ] **Step 2: Write the fixture test**

Create `OffshootsTests/ScreenshotFixtureTests.swift`:

```swift
//
//  ScreenshotFixtureTests.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 9/26/26.
//

import Foundation
import Testing
@testable import Offshoots

/// Pins every number the App Store shots show. `scripts/screenshots.sh` shifts
/// `screenshots.json` from its 2026-09-27 anchor to the capture day, so these
/// values hold on any capture day.
@MainActor
struct ScreenshotFixtureTests {

    /// The fixture's anchor day
    static let now = ISO8601DateFormatter().date(from: "2026-09-27T12:00:00Z")!

    private func decisions() throws -> [Decision] {
        try Fixture.load("screenshots")
    }

    @Test func counts() throws {
        let decisions = try decisions()
        #expect(decisions.count == 12)
        #expect(decisions.filter { $0.actual == nil }.count == 2)
        #expect(AnalyticsEngine.markedCount(from: decisions) == 10)
    }

    @Test func quickStats() throws {
        let decisions = try decisions()
        #expect(AnalyticsEngine.goodOutcomePercentage(from: decisions) == 60)
        #expect(AnalyticsEngine.topCategory(from: decisions) == "Work")
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .improving, isSoFar: false))
    }

    @Test func accuracy() throws {
        let decisions = try decisions()
        #expect(AnalyticsEngine.accuracyBreakdown(from: decisions) == AccuracyBreakdown(correct: 7, close: 1, incorrect: 2))
        #expect(AnalyticsEngine.predictionAccuracy(from: decisions) == 70)
    }

    @Test func optimism() throws {
        let bias = try #require(AnalyticsEngine.optimismBias(from: try decisions()))
        #expect(bias.averageGap == 0.5)
        #expect(bias.sample == 10)
        #expect(bias.lean == .optimistic)
    }

    @Test func outcomePercentagesAreWhole() throws {
        let shares = AnalyticsEngine.outcomeDistribution(from: try decisions())
        #expect(shares.map(\.outcome) == DecisionOutcome.allCases)
        #expect(shares.map(\.percent) == [10, 10, 20, 40, 20])
    }

    @Test func oneRevisitIsDueAndPendingAreUpcoming() throws {
        let decisions = try decisions()
        let ready = decisions.filter { $0.isReadyForReview(asOf: Self.now) }
        #expect(ready.map(\.title) == ["Ask for a four-day week"])
        let upcoming = decisions.filter { $0.actual == nil && !$0.isReadyForReview(asOf: Self.now) }
        #expect(upcoming.count == 2)
    }

    @Test func timelineDecisionHasTwoRevisits() throws {
        let decision = try #require(try decisions().first { $0.title == "Say yes to leading the offsite" })
        #expect(decision.actual == .bad)
        #expect(decision.revisits.map(\.outcome) == [.neutral, .good])
        #expect(decision.currentOutcome == .good)
    }

    @Test func starterSuggestionsAreHidden() throws {
        #expect(StarterSuggestion.available(given: try decisions()).isEmpty)
    }
}
```

- [ ] **Step 3: Run the tests**

Run: `xcodebuild -project Offshoots.xcodeproj -scheme Offshoots -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -only-testing:OffshootsTests/ScreenshotFixtureTests test`
Expected: all pass. If a value is off, fix the **fixture** (the spec's rule), then run again. If `DecisionOutcome.allCases` does not compare with `==` against `[DecisionOutcome]` because of the type, use `Array(DecisionOutcome.allCases)`.

- [ ] **Step 4: Commit**

```bash
git add docs/fixtures/screenshots.json OffshootsTests/ScreenshotFixtureTests.swift
git commit -m "Screenshot fixture with a test that pins its numbers

12 decisions anchored to 2026-09-27: 60% good, Work on top, Trend
Improving, 70% accuracy, Optimistic 0.5, whole outcome percentages,
one revisit due, and a Bad -> Neutral -> Good timeline.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: `scripts/screenshots.sh`

**Files:**
- Create: `scripts/screenshots.sh` (executable)
- Modify: `.gitignore`, `CLAUDE.md`, `CHANGELOG.md`, `DECISIONS.md`

**Interfaces:**
- Consumes: `docs/fixtures/screenshots.json` (Task 3).
- Produces: `scripts/screenshots.sh [setup]` and `scripts/screenshots.sh shot <name>`. Task 5 uses both.

- [ ] **Step 1: Write the script**

Create `scripts/screenshots.sh`:

```zsh
#!/bin/zsh
# App Store capture setup for Offshoots. Raw captures only: captions and frames
# happen in a separate finishing process.
#
# setup (the default) erases the iPhone 18 Pro Max (iOS 27.0), sets dark mode and
# a 9:41 status bar, builds and installs the app, loads docs/fixtures/screenshots.json
# shifted from its 2026-09-27 anchor to today, skips the splash, and launches.
# Then drive the taps (Claude's simulator tool, or by hand) and capture each shot:
#
#   01-dashboard   Dashboard, top of screen. No row text half under the tab bar.
#   02-log         Log tab. Title "Move to the Denver office", category Work,
#                  note "Better team, longer winters. Leaning yes.", stakes High,
#                  prediction Good. Scroll until the outcome labels clear the
#                  tab bar. DO NOT SAVE: a save asks for notification permission.
#   03-detail      Decisions > History > "Say yes to leading the offsite".
#                  Show the result line and the Bad > Neutral > Good timeline.
#   04-revisit     From 03, Revisit Decision. Pick Great, note "It led to a
#                  promotion talk." DO NOT SAVE. Cancel afterwards.
#   05-decisions   Decisions tab, top of screen: Ready to Review, Upcoming, History.
#   06-accuracy    Insights. Prediction Accuracy and Optimism fully in view.
#   07-patterns    Insights. Categories and Outcomes fully in view.
#
# Usage:
#   scripts/screenshots.sh              # setup
#   scripts/screenshots.sh shot 01-dashboard
#
# DEVICE, OS and SCREENSHOT_OUT_DIR override the defaults.
set -euo pipefail

BUNDLE=com.geoffrey.silva.Offshoots
DEVICE=${DEVICE:-"iPhone 18 Pro Max"}
OS=${OS:-27.0}
ANCHOR=2026-09-27
ROOT=${0:A:h:h}
FIXTURE="$ROOT/docs/fixtures/screenshots.json"
DERIVED="$ROOT/build/screenshots-dd"
OUT_DIR=${SCREENSHOT_OUT_DIR:-"$HOME/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/$(date +%F)"}

# UDID of the available simulator named $DEVICE on iOS $OS
udid() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
name, runtime = sys.argv[1], "iOS-" + sys.argv[2].replace(".", "-")
for key, devices in json.load(sys.stdin)["devices"].items():
    if key.endswith(runtime):
        for device in devices:
            if device["name"] == name:
                print(device["udid"])
                sys.exit(0)
sys.exit(1)' "$DEVICE" "$OS"
}

require_udid() {
  udid || { echo "No available simulator named '$DEVICE' on iOS $OS." >&2; exit 1; }
}

# The fixture with every ISO 8601 date moved by (today - anchor) in whole days
shifted_fixture() {
  python3 - "$FIXTURE" "$ANCHOR" <<'PY'
import re, sys
from datetime import date, datetime, timedelta
path, anchor = sys.argv[1], date.fromisoformat(sys.argv[2])
offset = timedelta(days=(date.today() - anchor).days)
def shift(match):
    moved = datetime.strptime(match.group(0), "%Y-%m-%dT%H:%M:%SZ") + offset
    return moved.strftime("%Y-%m-%dT%H:%M:%SZ")
with open(path) as file:
    sys.stdout.write(re.sub(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", shift, file.read()))
PY
}

setup() {
  local id; id=$(require_udid)
  local developer_dir; developer_dir=$(xcode-select -p)
  local simulator_app="$developer_dir/../Applications/DeviceHub.app"
  [[ -d $simulator_app ]] || simulator_app="$developer_dir/Applications/Simulator.app"
  echo "📱 $DEVICE, iOS $OS ($id)"

  echo "🧹 Erasing for a clean state…"
  xcrun simctl shutdown "$id" 2>/dev/null || true
  xcrun simctl erase "$id"
  xcrun simctl boot "$id"
  open "$simulator_app"
  xcrun simctl bootstatus "$id" -b

  echo "🌙 Dark mode, 9:41 status bar…"
  xcrun simctl ui "$id" appearance dark
  xcrun simctl status_bar "$id" override --time "9:41" \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState charged --batteryLevel 100

  echo "🔨 Building…"
  xcodebuild -project "$ROOT/Offshoots.xcodeproj" -scheme Offshoots -configuration Debug \
    -destination "id=$id" -derivedDataPath "$DERIVED" build
  xcrun simctl install "$id" "$DERIVED/Build/Products/Debug-iphonesimulator/Offshoots.app"

  echo "🌱 Loading the screenshot data, shifted to today…"
  local container; container=$(xcrun simctl get_app_container "$id" "$BUNDLE" data)
  mkdir -p "$container/Documents"
  shifted_fixture > "$container/Documents/decisions.json"
  xcrun simctl spawn "$id" defaults write "$BUNDLE" hasSeenSplash -bool YES
  xcrun simctl launch "$id" "$BUNDLE" >/dev/null

  echo "✅ Ready. Capture each shot (see the notes at the top of this script):"
  for name in 01-dashboard 02-log 03-detail 04-revisit 05-decisions 06-accuracy 07-patterns; do
    echo "   scripts/screenshots.sh shot $name"
  done
  echo "   Output: $OUT_DIR"
}

shot() {
  local name=${1:?usage: scripts/screenshots.sh shot <name>}
  local id; id=$(require_udid)
  mkdir -p "$OUT_DIR"
  xcrun simctl io "$id" screenshot "$OUT_DIR/$name.png"
  echo "📸 $OUT_DIR/$name.png"
}

case ${1:-setup} in
  setup) setup ;;
  shot) shift; shot "$@" ;;
  *) echo "Usage: scripts/screenshots.sh [setup | shot <name>]" >&2; exit 1 ;;
esac
```

Run: `chmod +x scripts/screenshots.sh`

- [ ] **Step 2: Check the date shift alone**

Run: `zsh -c 'source <(sed -n "/^shifted_fixture()/,/^}/p" scripts/screenshots.sh); FIXTURE=docs/fixtures/screenshots.json ANCHOR=2026-09-27 shifted_fixture' | python3 -m json.tool | head -12`
Expected: valid JSON. On 2026-09-26 every date is one day earlier (the couch `createdAt` is `2026-09-25T12:00:00Z`). On 2026-09-27 the dates are unchanged.

- [ ] **Step 3: Ignore the build folder**

Add to `.gitignore`, after `DerivedData/`:

```
build/
```

- [ ] **Step 4: Run setup**

Run: `scripts/screenshots.sh`
Expected: the build succeeds, and the app opens on the Dashboard on the iPhone 18 Pro Max: 9:41, dark, no splash, "Ready to Review" with "Ask for a four-day week", Pending 2 / Completed 10 / Total 12, Quick Stats 60% good, Work, Trend Improving.

If `get_app_container` fails right after install, add `xcrun simctl launch "$id" "$BUNDLE" >/dev/null; xcrun simctl terminate "$id" "$BUNDLE"` before it, and note it in CLAUDE.md.

Take a check screenshot into the session scratchpad, not the Captures library: `SCREENSHOT_OUT_DIR=<scratchpad> scripts/screenshots.sh shot 00-setup-check`. Check the image with `sips -g pixelWidth -g pixelHeight`. Record the size (the spec expects 1320 × 2868; confirm it).

- [ ] **Step 5: Docs**

`CLAUDE.md`, add after the "Seed script" bullet in Simulator Testing:

```markdown
- **App Store screenshots:** `scripts/screenshots.sh` erases the iPhone 18 Pro
  Max (iOS 27.0), sets dark mode and a 9:41 status bar, builds, installs and
  loads `docs/fixtures/screenshots.json`. The fixture is anchored to 2026-09-27,
  and the script moves every date to today, so the shots never drift.
  `ScreenshotFixtureTests` pins the numbers. Capture with
  `scripts/screenshots.sh shot 01-dashboard`; files go to
  `~/Documents/Dev Workstation/App Images/ASC Screenshots/Offshoots/Captures/<date>/`.
  The shot list and scroll positions are at the top of the script. Do not save
  on 02 (Log) or 04 (Revisit): a save asks for notification permission.
  The 6.9" capture size is <record the Step 4 value>.
```

`CHANGELOG.md`, add a heading under the in-progress section:

```markdown
### 2026-09-26 — Screenshot pipeline, stop 2
- `scripts/screenshots.sh` sets up the iPhone 18 Pro Max for App Store captures: dark mode, 9:41, seeded data moved to today, no splash.
- `docs/fixtures/screenshots.json` with `ScreenshotFixtureTests`, which pins every number the shots show.
```

`DECISIONS.md`:

```markdown
## 2026-09-26 (Screenshot pipeline: raw captures from a date-shifted JSON fixture)
**Decision:** `scripts/screenshots.sh` loads `docs/fixtures/screenshots.json`, anchored to 2026-09-27 and moved to the capture day. Dark mode only, 7 shots (Dashboard, Log, Detail, Revisit, Decisions, Insights accuracy, Insights patterns), raw captures only. Captions and frames happen in a separate finishing process.
**Why:** It extends the `seed.sh` method this repo already has and ships no screenshot code in the app. The date shift keeps trend windows, due revisits and charts the same on any capture day. A test pins the numbers.
**Alternative considered:** A Swift `ScreenshotSeed` behind a `-screenshots` argument, as in Task(ed) and AisleWise. It works, but it ships fixture code in the app binary.
```

- [ ] **Step 6: Commit**

```bash
git add scripts/screenshots.sh .gitignore CLAUDE.md CHANGELOG.md DECISIONS.md
git commit -m "Add scripts/screenshots.sh for App Store captures

Erase the iPhone 18 Pro Max, set dark mode and a 9:41 status bar,
build, install, load the screenshot fixture moved to today, skip the
splash, and launch. 'shot <name>' saves to the dated Captures folder.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: STOP 2.** Show Geoff the seeded Dashboard, the recorded capture size, and the test result. Wait for approval.

---

## Stop 3 — Capture pass

### Task 5: Capture the 7 shots and review them

**Files:**
- Output only: the dated Captures folder (outside the repo)
- Modify: `TODO.md`, `CHANGELOG.md`

**Interfaces:**
- Consumes: `scripts/screenshots.sh setup` and `shot <name>` (Task 4).

Tap rules from CLAUDE.md: pass `duration: 0.15` to simulator taps. Do not start a swipe at the tab bar; start above it. Take a screenshot before each tap on a menu item, and tap at once. Reattach after a reinstall. Get the screen size in points from the tool's `launch` or first screenshot. Do not reuse iPhone 18 Pro coordinates.

- [ ] **Step 1: Fresh setup**

Run: `scripts/screenshots.sh`. Then `attach` the simulator tool to the iPhone 18 Pro Max.

- [ ] **Step 2: 01-dashboard**

Dashboard, scrolled to the top. Check that no row text sits half under the tab bar. If it does, scroll a little until the tab bar covers only space between rows. Run `scripts/screenshots.sh shot 01-dashboard`.

- [ ] **Step 3: 02-log**

Log tab. Tap the title field and type "Move to the Denver office". Keep the category Work. Tap Notes and type "Better team, longer winters. Leaning yes." Close the keyboard. Stakes: High. Expected Outcome: Good. Scroll until the outcome labels are fully above the tab bar. **Do not save.** Run `scripts/screenshots.sh shot 02-log`.

- [ ] **Step 4: 03-detail**

Decisions tab > History > "Say yes to leading the offsite". Scroll to show the result line and the revisit timeline (Bad → Neutral → Good). Run `scripts/screenshots.sh shot 03-detail`.

- [ ] **Step 5: 04-revisit**

On that detail screen, tap Revisit Decision. Pick Great. Type the note "It led to a promotion talk." Close the keyboard. Run `scripts/screenshots.sh shot 04-revisit`. Tap **Cancel**. Do not tap Save Revisit.

- [ ] **Step 6: 05-decisions**

Go back to the Decisions list and scroll to the top. Run `scripts/screenshots.sh shot 05-decisions`.

- [ ] **Step 7: 06-accuracy and 07-patterns**

Insights tab. Scroll until Prediction Accuracy and Optimism are fully in view. Run `scripts/screenshots.sh shot 06-accuracy`. Scroll up until Categories and Outcomes are fully in view. Run `scripts/screenshots.sh shot 07-patterns`.

- [ ] **Step 8: Review every image**

For each of the 7 files: run `sips -g pixelWidth -g pixelHeight` and open the image with Read. Check:
- The size matches the Task 4 value, and all 7 are the same size.
- 9:41, full battery and signal, dark mode.
- No text cut off, and no text half hidden under the tab bar or the navigation bar.
- No alert, keyboard, splash, or cursor.
- The numbers match `ScreenshotFixtureTests`: 60% good, Work, Improving, 70%, 7 / 1 / 2, Optimistic 0.5, 10 / 10 / 20 / 40 / 20%.
- 02 and 04 show the typed text. Nothing was saved: the Dashboard still shows Total 12.

Retake any failed shot (same name; a same-day retake replaces the file). Write a short review table: shot, size, result, notes.

- [ ] **Step 9: Docs**

`TODO.md`, under Done (newest first):

```markdown
- [x] Screenshot pipeline: app fixes, fixture, `scripts/screenshots.sh`, first 7-shot capture (branch `screenshot-pipeline`) — 2026-09-26
```

`CHANGELOG.md`, under the in-progress section:

```markdown
### 2026-09-26 — Screenshot pipeline, stop 3
- First full capture pass: 7 dark-mode shots in `ASC Screenshots/Offshoots/Captures/<date>/`.
```

Use the real capture date in both entries if it is not 2026-09-26.

- [ ] **Step 10: Commit**

```bash
git add TODO.md CHANGELOG.md
git commit -m "Record the first screenshot capture pass

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 11: STOP 3.** Give Geoff the Captures folder path and the review table. The merge to `main` is Geoff's decision after he checks the images.
