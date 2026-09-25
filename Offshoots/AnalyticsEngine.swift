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

    /// Returns the most common category from all decisions, or "Tied" when
    /// two or more categories share the top count
    static func topCategory(from decisions: [Decision]) -> String {
        guard !decisions.isEmpty else { return "None" }

        let categoryCounts = Dictionary(grouping: decisions, by: { $0.category })
            .mapValues { $0.count }

        guard let topCount = categoryCounts.values.max() else { return "None" }
        let leaders = categoryCounts.filter { $0.value == topCount }
        guard leaders.count == 1, let leader = leaders.first else { return "Tied" }
        return leader.key.rawValue.capitalized
    }

    /// Returns the percentage of positive outcomes (good or very good) from completed decisions.
    /// Uses the latest rating, so a revisit changes how a decision turned out
    static func goodOutcomePercentage(from decisions: [Decision]) -> Int {
        let completed = decisions.filter { $0.actual != nil }
        guard !completed.isEmpty else { return 0 }

        let positiveCount = completed.filter { $0.currentOutcome?.isPositive == true }.count
        let percentage = Double(positiveCount) / Double(completed.count) * 100
        return Int(percentage.rounded())
    }

    /// Counts first ratings that match the prediction exactly, and those that do not
    static func accuracyBreakdown(from decisions: [Decision]) -> AccuracyBreakdown {
        let completed = decisions.filter { $0.actual != nil }
        let correct = completed.filter { $0.expected == $0.actual }.count
        return AccuracyBreakdown(correct: correct, incorrect: completed.count - correct)
    }

    /// Returns the prediction accuracy percentage from all completed decisions
    static func predictionAccuracy(from decisions: [Decision]) -> Int {
        accuracyBreakdown(from: decisions).percent
    }

    /// Compares prediction accuracy in the last 30 days with the 30 days before,
    /// by the date each outcome was marked. Each window needs 3 decisions
    static func qualityTrend(from decisions: [Decision], now: Date = Date()) -> QualityTrend {
        let calendar = Calendar.current
        let last30Days = calendar.date(byAdding: .day, value: -30, to: now)!
        let last60Days = calendar.date(byAdding: .day, value: -60, to: now)!

        let recent = decisions.filter { ($0.resolvedDate ?? .distantPast) >= last30Days }
        let previous = decisions.filter {
            guard let date = $0.resolvedDate else { return false }
            return date >= last60Days && date < last30Days
        }

        guard recent.count >= minimumTrendSample, previous.count >= minimumTrendSample else { return .tooEarly }

        let difference = accuracyBreakdown(from: recent).fraction - accuracyBreakdown(from: previous).fraction

        if difference > 0.1 {
            return .improving
        } else if difference < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    static let minimumTrendSample = 3
}

struct AccuracyBreakdown: Equatable {
    let correct: Int
    let incorrect: Int

    var total: Int { correct + incorrect }

    var fraction: Double {
        total == 0 ? 0 : Double(correct) / Double(total)
    }

    var percent: Int {
        Int((fraction * 100).rounded())
    }
}

enum QualityTrend: Equatable {
    case improving
    case stable
    case declining
    case tooEarly

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .tooEarly: return "Too early"
        }
    }
}
