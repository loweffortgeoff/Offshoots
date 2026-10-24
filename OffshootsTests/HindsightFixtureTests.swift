import Testing
@testable import Offshoots

@MainActor
struct HindsightFixtureTests {
    @Test func syntheticFixtureHasTheExpectedDistinctDecisions() throws {
        let decisions = try Fixture.load("hindsight-check-ins")
        let entries = HindsightSummary.entries(from: decisions)
        #expect(decisions.count == 9)
        #expect(entries.count == 8)
        #expect(HindsightSummary.count(.sameApproach, in: entries) == 2)
        #expect(HindsightSummary.count(.differentApproach, in: entries) == 3)
        #expect(HindsightSummary.count(.differentChoice, in: entries) == 1)
        #expect(HindsightSummary.count(.notSure, in: entries) == 2)
        #expect(entries.first { $0.title == "Change the check-in approach" }?.outcome == .bad)
    }
}
