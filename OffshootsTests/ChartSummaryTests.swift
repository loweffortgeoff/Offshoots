//
//  ChartSummaryTests.swift
//  OffshootsTests
//

import Testing
@testable import Offshoots

@MainActor
struct ChartSummaryTests {

    @Test func activityGivesTotalAndBusiestDay() {
        #expect(ChartSummary.activity(dailyCounts: [0, 2, 0, 3, 1], days: 30)
                == "6 decisions in the last 30 days. Most in one day: 3.")
    }

    @Test func activityUsesTheSingular() {
        #expect(ChartSummary.activity(dailyCounts: [0, 1, 0], days: 30)
                == "1 decision in the last 30 days. Most in one day: 1.")
    }

    @Test func categoriesNameASingleLeader() {
        let summary = ChartSummary.categories([(.work, 5), (.health, 3), (.home, 1)])
        #expect(summary == "Top category: Work. Work 5, Health 3, Home 1.")
    }

    @Test func categoriesNameATie() {
        let summary = ChartSummary.categories([(.health, 2), (.money, 2), (.work, 2), (.home, 1)])
        #expect(summary == "Tied for top: Health, Money and Work. Health 2, Money 2, Work 2, Home 1.")
    }

    @Test func categoriesWhenEmpty() {
        #expect(ChartSummary.categories([]) == "No categories yet.")
    }

    @Test func outcomesReadEachShare() {
        let shares = [
            OutcomeShare(outcome: .good, count: 2, percent: 50),
            OutcomeShare(outcome: .neutral, count: 1, percent: 25),
            OutcomeShare(outcome: .bad, count: 1, percent: 25)
        ]
        #expect(ChartSummary.outcomes(shares) == "Good 50%, Neutral 25%, Bad 25%.")
    }

    @Test func trendReadsZeroCounts() {
        #expect(ChartSummary.trend(positive: 3, neutral: 0, negative: 1, weeks: 8)
                == "Last 8 weeks: 3 positive, 0 neutral, 1 negative.")
    }
}
