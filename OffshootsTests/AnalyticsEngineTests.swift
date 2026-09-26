//
//  AnalyticsEngineTests.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 9/25/26.
//

import Foundation
import Testing
@testable import Offshoots

/// Expected values match the Insights fixtures described in CLAUDE.md, so the
/// tests and `scripts/seed.sh` share one source of truth.
@MainActor
struct AnalyticsEngineTests {

    /// Inside the fixtures' 2026-09-25 to 2026-09-30 window, so the trend is stable over time
    static let now = ISO8601DateFormatter().date(from: "2026-09-27T12:00:00Z")!

    // MARK: - insights-seed.json

    @Test func goodPercentageUsesLatestRating() throws {
        let decisions = try Fixture.load("insights-seed")
        #expect(AnalyticsEngine.goodOutcomePercentage(from: decisions) == 50)
    }

    @Test func topCategoryReportsTie() throws {
        let decisions = try Fixture.load("insights-seed")
        #expect(AnalyticsEngine.topCategory(from: decisions) == "Tied")
    }

    @Test func accuracyCountsNearMissesApart() throws {
        let decisions = try Fixture.load("insights-seed")
        let breakdown = AnalyticsEngine.accuracyBreakdown(from: decisions)
        #expect(breakdown == AccuracyBreakdown(correct: 4, close: 1, incorrect: 1))
        #expect(AnalyticsEngine.predictionAccuracy(from: decisions) == 67)
    }

    @Test func optimismBiasUsesFirstRating() throws {
        let decisions = try Fixture.load("insights-seed")
        let bias = try #require(AnalyticsEngine.optimismBias(from: decisions))
        #expect(bias.averageGap == 0.5)
        #expect(bias.sample == 6)
        #expect(bias.lean == .optimistic)
    }

    @Test func trendImproves() throws {
        let decisions = try Fixture.load("insights-seed")
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .improving, isSoFar: false))
    }

    // MARK: - insights-seed-too-early.json

    @Test func trendIsTooEarlyWithoutAPreviousWindow() throws {
        let decisions = try Fixture.load("insights-seed-too-early")
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == TrendResult(trend: .tooEarly, isSoFar: false))
    }

    // MARK: - Edge cases

    @Test func emptyInput() {
        #expect(AnalyticsEngine.topCategory(from: []) == "None")
        #expect(AnalyticsEngine.goodOutcomePercentage(from: []) == 0)
        #expect(AnalyticsEngine.predictionAccuracy(from: []) == 0)
        #expect(AnalyticsEngine.optimismBias(from: []) == nil)
        #expect(AnalyticsEngine.qualityTrend(from: [], now: Self.now).trend == .tooEarly)
    }

    @Test(arguments: [
        (0.25, OptimismBias.Lean.optimistic),
        (0.24, .calibrated),
        (-0.24, .calibrated),
        (-0.25, .pessimistic),
    ])
    func leanThresholds(gap: Double, lean: OptimismBias.Lean) {
        #expect(OptimismBias(averageGap: gap, sample: 3).lean == lean)
    }

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
}
