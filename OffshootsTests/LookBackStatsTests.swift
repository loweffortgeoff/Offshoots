import Testing
@testable import Offshoots

@MainActor
struct LookBackStatsTests {

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

    /// The free Optimism card averages the lean, so 6 worse and 7 better reads "Well calibrated".
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
