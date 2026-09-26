//
//  AnalyticsEngine.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation

struct AnalyticsEngine {

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

    /// Sorts first ratings into exact matches, misses by one step, and misses by more
    static func accuracyBreakdown(from decisions: [Decision]) -> AccuracyBreakdown {
        var correct = 0, close = 0, incorrect = 0
        for decision in decisions {
            guard let actual = decision.actual else { continue }
            switch abs(decision.expected.numericValue - actual.numericValue) {
            case 0: correct += 1
            case 1: close += 1
            default: incorrect += 1
            }
        }
        return AccuracyBreakdown(correct: correct, close: close, incorrect: incorrect)
    }

    /// Average of expected minus first rating, in steps on the 5-point scale.
    /// Positive means predictions run better than results. Nil below 3 decisions
    static func optimismBias(from decisions: [Decision]) -> OptimismBias? {
        let gaps = decisions.compactMap { decision in
            decision.actual.map { decision.expected.numericValue - $0.numericValue }
        }
        guard gaps.count >= minimumBiasSample else { return nil }
        return OptimismBias(averageGap: Double(gaps.reduce(0, +)) / Double(gaps.count), sample: gaps.count)
    }

    static let minimumBiasSample = 3

    /// Returns the prediction accuracy percentage from all completed decisions
    static func predictionAccuracy(from decisions: [Decision]) -> Int {
        accuracyBreakdown(from: decisions).percent
    }

    /// Steps from the prediction to the first rating. Positive means it went
    /// better than expected. Nil until an outcome is marked
    static func predictionGap(for decision: Decision) -> Int? {
        decision.actual.map { $0.numericValue - decision.expected.numericValue }
    }

    /// Decisions with a first rating
    static func markedCount(from decisions: [Decision]) -> Int {
        decisions.filter { $0.actual != nil }.count
    }

    /// Compares prediction accuracy in the last 30 days with the 30 days before,
    /// by the date each outcome was marked. Each window needs 3 decisions.
    /// Until then, with 6 or more marked decisions, it compares the older half
    /// of them with the newer half and flags the result as "so far"
    static func qualityTrend(from decisions: [Decision], now: Date = Date()) -> TrendResult {
        let calendar = Calendar.current
        let last30Days = calendar.date(byAdding: .day, value: -30, to: now)!
        let last60Days = calendar.date(byAdding: .day, value: -60, to: now)!

        let recent = decisions.filter { ($0.resolvedDate ?? .distantPast) >= last30Days }
        let previous = decisions.filter {
            guard let date = $0.resolvedDate else { return false }
            return date >= last60Days && date < last30Days
        }

        if recent.count >= minimumTrendSample, previous.count >= minimumTrendSample {
            return TrendResult(trend: compare(newer: recent, older: previous), isSoFar: false)
        }

        let marked = decisions
            .compactMap { decision in decision.resolvedDate.map { (decision, $0) } }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
        guard marked.count >= minimumSoFarSample else {
            return TrendResult(trend: .tooEarly, isSoFar: false)
        }

        // With an odd count, the newer half gets the extra decision
        let olderCount = marked.count / 2
        let older = Array(marked.prefix(olderCount))
        let newer = Array(marked.dropFirst(olderCount))
        return TrendResult(trend: compare(newer: newer, older: older), isSoFar: true)
    }

    private static func compare(newer: [Decision], older: [Decision]) -> QualityTrend {
        let difference = accuracyBreakdown(from: newer).fraction - accuracyBreakdown(from: older).fraction

        if difference > 0.1 {
            return .improving
        } else if difference < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    static let minimumTrendSample = 3
    static let minimumSoFarSample = 6
}

struct AccuracyBreakdown: Equatable {
    /// Exact match
    let correct: Int
    /// Off by one step
    let close: Int
    /// Off by two steps or more
    let incorrect: Int

    var total: Int { correct + close + incorrect }

    var fraction: Double {
        total == 0 ? 0 : Double(correct) / Double(total)
    }

    var percent: Int {
        Int((fraction * 100).rounded())
    }
}

struct OutcomeShare: Equatable {
    let outcome: DecisionOutcome
    let count: Int
    let percent: Int
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

struct TrendResult: Equatable {
    let trend: QualityTrend
    /// True when the trend compares the older and newer halves of all marked
    /// decisions, because the 30-day windows do not have enough data yet
    let isSoFar: Bool
}

struct OptimismBias: Equatable {
    let averageGap: Double
    let sample: Int

    enum Lean: Equatable {
        case optimistic
        case calibrated
        case pessimistic
    }

    /// Within a quarter step either way counts as calibrated
    var lean: Lean {
        if averageGap >= 0.25 { return .optimistic }
        if averageGap <= -0.25 { return .pessimistic }
        return .calibrated
    }
}
