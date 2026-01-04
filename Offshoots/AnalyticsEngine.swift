//
//  AnalyticsEngine.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation

struct AnalyticsEngine {

    /// Returns the decision quality score (0–100) for the last 30 days.
    /// Score = % of decisions where expected outcome == actual outcome.
    static func decisionQualityScore(from decisions: [Decision]) -> Int {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!

        // Filter: Only include completed decisions within last 30 days
        let recent = decisions.filter {
            $0.createdAt >= thirtyDaysAgo && $0.actual != nil
        }

        guard !recent.isEmpty else { return 0 }

        let matches = recent.filter { $0.expected == $0.actual }.count

        let score = Double(matches) / Double(recent.count) * 100
        return Int(score.rounded())
    }

    /// Returns the most common category from all decisions
    static func topCategory(from decisions: [Decision]) -> String {
        guard !decisions.isEmpty else { return "None" }

        let categoryCounts = Dictionary(grouping: decisions, by: { $0.category })
            .mapValues { $0.count }

        let topCategory = categoryCounts.max(by: { $0.value < $1.value })
        return topCategory?.key.rawValue.capitalized ?? "None"
    }

    /// Returns the percentage of positive outcomes (good or very good) from completed decisions
    static func goodOutcomePercentage(from decisions: [Decision]) -> Int {
        let completed = decisions.filter { $0.actual != nil }
        guard !completed.isEmpty else { return 0 }

        let positiveCount = completed.filter { $0.actual?.isPositive == true }.count
        let percentage = Double(positiveCount) / Double(completed.count) * 100
        return Int(percentage.rounded())
    }

    /// Returns the prediction accuracy percentage from all completed decisions
    static func predictionAccuracy(from decisions: [Decision]) -> Int {
        let completed = decisions.filter { $0.actual != nil }
        guard !completed.isEmpty else { return 0 }

        let matches = completed.filter { $0.expected == $0.actual }.count
        let percentage = Double(matches) / Double(completed.count) * 100
        return Int(percentage.rounded())
    }

    /// Returns a trend descriptor based on recent decision quality
    static func qualityTrend(from decisions: [Decision]) -> String {
        let now = Date()
        let last7Days = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let last14Days = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        let recentWeek = decisions.filter { $0.createdAt >= last7Days && $0.actual != nil }
        let previousWeek = decisions.filter {
            $0.createdAt >= last14Days && $0.createdAt < last7Days && $0.actual != nil
        }

        guard !recentWeek.isEmpty, !previousWeek.isEmpty else { return "Stable" }

        let recentScore = Double(recentWeek.filter { $0.expected == $0.actual }.count) / Double(recentWeek.count)
        let previousScore = Double(previousWeek.filter { $0.expected == $0.actual }.count) / Double(previousWeek.count)

        let difference = recentScore - previousScore

        if difference > 0.1 {
            return "Improving"
        } else if difference < -0.1 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
}
