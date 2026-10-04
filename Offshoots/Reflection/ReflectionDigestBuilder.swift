//
//  ReflectionDigestBuilder.swift
//  Offshoots
//

import Foundation

enum ReflectionDigestBuilder {
    static let maximumNotes = 8
    static let noteLimit = 140
    static let longNoteLimit = 400
    static let titleLimit = 120

    static func patterns(from decisions: [Decision], now: Date) -> PatternsDigest {
        let marked = decisions.filter { $0.actual != nil }
        return PatternsDigest(
            resolvedCount: marked.count,
            goodPercent: AnalyticsEngine.goodOutcomePercentage(from: decisions),
            accuracy: AnalyticsEngine.accuracyBreakdown(from: decisions),
            optimism: AnalyticsEngine.optimismBias(from: decisions),
            trend: AnalyticsEngine.qualityTrend(from: decisions, now: now),
            categories: groups(marked) { $0.category.rawValue.capitalized },
            stakes: groups(marked) { $0.stakes.label },
            revisitedCount: marked.filter { !$0.revisits.isEmpty }.count,
            revisitsChangingOutcome: marked.filter { $0.currentOutcome != $0.actual }.count,
            notes: recentNotes(in: marked)
        )
    }

    /// Nil until an outcome is marked.
    static func decision(_ decision: Decision) -> DecisionDigest? {
        guard let actual = decision.actual, let resolved = decision.resolvedDate else { return nil }
        return DecisionDigest(
            title: ReflectionText.clean(decision.title, limit: titleLimit) ?? "Untitled",
            category: decision.category.rawValue.capitalized,
            stakes: decision.stakes.label,
            expected: decision.expected.shortLabel,
            firstOutcome: actual.shortLabel,
            daysToFirstOutcome: days(from: decision.createdAt, to: resolved),
            timeline: decision.revisits.map {
                TimelineLine(
                    daysAfterFirstOutcome: days(from: resolved, to: $0.date),
                    outcome: $0.outcome.shortLabel,
                    note: ReflectionText.clean($0.note, limit: noteLimit)
                )
            },
            notes: ReflectionText.clean(decision.notes, limit: longNoteLimit),
            outcomeNote: ReflectionText.clean(decision.reflection, limit: longNoteLimit)
        )
    }

    // MARK: - Helpers

    private static func groups(_ decisions: [Decision], by label: (Decision) -> String) -> [GroupLine] {
        Dictionary(grouping: decisions, by: label)
            .map { label, items in
                GroupLine(label: label, resolved: items.count, exact: items.filter { $0.expected == $0.actual }.count)
            }
            .sorted { $0.resolved != $1.resolved ? $0.resolved > $1.resolved : $0.label < $1.label }
    }

    private static func recentNotes(in decisions: [Decision]) -> [String] {
        var dated: [(date: Date, text: String)] = []
        for decision in decisions {
            if let text = ReflectionText.clean(decision.notes, limit: noteLimit) {
                dated.append((decision.createdAt, text))
            }
            if let text = ReflectionText.clean(decision.reflection, limit: noteLimit) {
                dated.append((decision.resolvedDate ?? decision.createdAt, text))
            }
            for revisit in decision.revisits {
                if let text = ReflectionText.clean(revisit.note, limit: noteLimit) {
                    dated.append((revisit.date, text))
                }
            }
        }
        return dated.sorted { $0.date > $1.date }.prefix(maximumNotes).map(\.text)
    }

    /// Whole calendar days, never negative.
    private static func days(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let count = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
        return max(0, count)
    }
}
