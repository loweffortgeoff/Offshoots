//
//  ChartSummary.swift
//  Offshoots
//

import Foundation

/// Short spoken summaries for the Insights charts. VoiceOver reads a Swift Chart
/// mark by mark ("Sep 6, 2026 at 00 to Sep 13… 0 to 0"), so each chart is one
/// element with one of these as its label.
enum ChartSummary {

    /// Decision Activity: the total over the window and the busiest day
    static func activity(dailyCounts: [Int], days: Int) -> String {
        let total = dailyCounts.reduce(0, +)
        let most = dailyCounts.max() ?? 0
        return "\(decisions(total)) in the last \(days) days. Most in one day: \(most)."
    }

    /// Categories, most first. A tie for the top is named as a tie, as on the Dashboard.
    static func categories(_ data: [(category: DecisionCategory, count: Int)]) -> String {
        guard let top = data.first else { return "No categories yet." }
        let leaders = data.filter { $0.count == top.count }.map { name($0.category) }
        let lead = leaders.count == 1
            ? "Top category: \(leaders[0])."
            : "Tied for top: \(list(leaders))."
        let counts = data.map { "\(name($0.category)) \($0.count)" }.joined(separator: ", ")
        return "\(lead) \(counts)."
    }

    /// Outcomes: the share of each latest rating, in the legend's order
    static func outcomes(_ shares: [OutcomeShare]) -> String {
        shares.map { "\($0.outcome.compactLabel) \($0.percent)%" }.joined(separator: ", ") + "."
    }

    /// Outcome Trends: the totals behind the weekly bars
    static func trend(positive: Int, neutral: Int, negative: Int, weeks: Int) -> String {
        "Last \(weeks) weeks: \(positive) positive, \(neutral) neutral, \(negative) negative."
    }

    private static func decisions(_ count: Int) -> String {
        count == 1 ? "1 decision" : "\(count) decisions"
    }

    private static func name(_ category: DecisionCategory) -> String {
        category.rawValue.capitalized
    }

    private static func list(_ names: [String]) -> String {
        names.count <= 2
            ? names.joined(separator: " and ")
            : names.dropLast().joined(separator: ", ") + " and " + names.last!
    }
}
