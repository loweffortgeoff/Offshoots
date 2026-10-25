import Testing
@testable import Offshoots

@MainActor
struct LookBackStatsTests {

    @Test func directHistoryCountsAllMarkedDecisionsWithoutNotes() {
        let decisions = (0..<8).map { _ in Make.marked(.neutral, .good) }
            + [Make.decision(), Make.decision(category: .money, actual: .bad)]
        let stats = LookBackStats.build(category: .work, decisions: decisions)
        #expect(stats.total == 8)
        #expect(stats.betterCount == 8)
        #expect(stats.summary == "Of the 8 Work decisions you marked, 8 went better.")
        #expect(stats.spokenRow("Expected", \.expected) == "Expected: 8 Neutral.")
        #expect(stats.spokenRow("Turned out", \.actual) == "Turned out: 8 Good.")
    }

    @Test func directHistoryKeepsFirstOutcomeAfterRevisiting() {
        let decision = Make.decision(expected: .neutral, actual: .good,
            revisits: [Revisit(date: Make.day(20), outcome: .bad, note: "Changed later")])
        let stats = LookBackStats.build(category: .work, decisions: [decision])
        #expect(stats.betterCount == 1)
        #expect(stats.pairs == [OutcomePair(expected: .neutral, actual: .good)])
        #expect(stats.headline == nil)
    }

    @Test func directHistoryUpdatesWithCategoryAndNewOutcome() {
        var decisions = [Make.marked(.bad, .good), Make.decision(category: .home, expected: .good)]
        #expect(LookBackStats.build(category: .home, decisions: decisions).total == 0)
        decisions[1].actual = .bad
        let stats = LookBackStats.build(category: .home, decisions: decisions)
        #expect(stats.total == 1)
        #expect(stats.worseCount == 1)
        #expect(stats.betterCount == 0)
        #expect(stats.category == "Home")
    }

    private func stats(worse: Int = 0, asPredicted: Int = 0, better: Int = 0) -> LookBackStats {
        let pairs = Array(repeating: OutcomePair(expected: .good, actual: .bad), count: worse)
            + Array(repeating: OutcomePair(expected: .good, actual: .good), count: asPredicted)
            + Array(repeating: OutcomePair(expected: .bad, actual: .good), count: better)
        return LookBackStats(category: "Work", pairs: pairs)
    }

    @Test func noHeadlineBelowTheMinimum() {
        #expect(LookBackStats.minimumForHeadline == 5)
        #expect(stats(better: 4).headline == nil)
    }

    @Test func mostlyBetterBeatsPredictions() {
        #expect(stats(worse: 1, asPredicted: 1, better: 3).headline == "Your Work decisions tend to beat your predictions")
    }

    @Test func mostlyWorseFallsShort() {
        #expect(stats(worse: 3, asPredicted: 1, better: 1).headline == "Your Work decisions tend to fall short of your predictions")
    }

    @Test func mostlyAsPredictedHoldsUp() {
        #expect(stats(worse: 1, asPredicted: 4, better: 1).headline == "Your Work predictions tend to hold up")
    }

    /// A 6-worse / 7-better split has no clear direction.
    /// Look Back counts directions instead, and says nothing when no group is a majority.
    @Test func aSplitHasNoHeadline() {
        #expect(stats(worse: 6, better: 7).headline == nil)
        #expect(stats(worse: 2, asPredicted: 2, better: 2).headline == nil)
    }

    @Test func aMajorityNeedsAClearLead() {
        #expect(LookBackStats.headlineMargin == 2)
        #expect(stats(worse: 4, better: 5).headline == nil)
        #expect(stats(worse: 3, better: 5).headline == "Your Work decisions tend to beat your predictions")
    }

    @Test func halfIsNotAMajority() {
        #expect(stats(worse: 3, better: 3).headline == nil)
    }

    @Test func countsRunWorstFirstAndSkipEmptyOutcomes() {
        let stats = LookBackStats(category: "Work", pairs: [
            OutcomePair(expected: .veryGood, actual: .veryBad),
            OutcomePair(expected: .neutral, actual: .good),
            OutcomePair(expected: .neutral, actual: .good),
        ])
        #expect(stats.counts(\.expected).map(\.outcome) == [.neutral, .veryGood])
        #expect(stats.counts(\.actual).map(\.count) == [1, 2])
        #expect(stats.spokenRow("Turned out", \.actual) == "Turned out: 1 Very Bad, 2 Good.")
    }
}
