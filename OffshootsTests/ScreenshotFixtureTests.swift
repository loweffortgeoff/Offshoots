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
