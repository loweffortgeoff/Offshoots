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
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == .improving)
    }

    // MARK: - insights-seed-too-early.json

    @Test func trendIsTooEarlyWithoutAPreviousWindow() throws {
        let decisions = try Fixture.load("insights-seed-too-early")
        #expect(AnalyticsEngine.qualityTrend(from: decisions, now: Self.now) == .tooEarly)
    }

    // MARK: - Edge cases

    @Test func emptyInput() {
        #expect(AnalyticsEngine.topCategory(from: []) == "None")
        #expect(AnalyticsEngine.goodOutcomePercentage(from: []) == 0)
        #expect(AnalyticsEngine.predictionAccuracy(from: []) == 0)
        #expect(AnalyticsEngine.optimismBias(from: []) == nil)
        #expect(AnalyticsEngine.qualityTrend(from: [], now: Self.now) == .tooEarly)
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
}
