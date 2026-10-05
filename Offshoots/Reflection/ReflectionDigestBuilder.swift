//
//  ReflectionDigestBuilder.swift
//  Offshoots
//

import Foundation

enum ReflectionDigestBuilder {
    /// A fixed cap per group, so one large group cannot push out the others.
    /// Sized for the 4,096-token context on iOS 26 (Reflection Depth plan, chunk 1).
    static let notesPerGroup = 15
    static let noteLimit = 140
    static let longNoteLimit = 400
    static let titleLimit = 120

    static func patterns(from decisions: [Decision]) -> PatternsDigest {
        let marked = decisions.filter { $0.actual != nil }
        let worse = marked.filter { (AnalyticsEngine.predictionGap(for: $0) ?? 0) < 0 }
        let asPredicted = marked.filter { AnalyticsEngine.predictionGap(for: $0) == 0 }
        let better = marked.filter { (AnalyticsEngine.predictionGap(for: $0) ?? 0) > 0 }
        return PatternsDigest(
            resolvedCount: marked.count,
            worseCount: worse.count,
            asPredictedCount: asPredicted.count,
            betterCount: better.count,
            worse: noteLines(in: worse),
            asPredicted: noteLines(in: asPredicted),
            better: noteLines(in: better)
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

    /// The log note, the outcome note and every revisit note, newest first, capped per group.
    private static func noteLines(in decisions: [Decision]) -> [NoteLine] {
        var dated: [(date: Date, line: NoteLine)] = []
        for decision in decisions {
            let category = decision.category.rawValue.capitalized
            let stakes = decision.stakes.label
            func add(_ text: String?, on date: Date) {
                guard let text = ReflectionText.clean(text, limit: noteLimit) else { return }
                dated.append((date, NoteLine(category: category, stakes: stakes, text: text)))
            }
            add(decision.notes, on: decision.createdAt)
            add(decision.reflection, on: decision.resolvedDate ?? decision.createdAt)
            for revisit in decision.revisits {
                add(revisit.note, on: revisit.date)
            }
        }
        return dated.sorted { $0.date > $1.date }.prefix(notesPerGroup).map(\.line)
    }

    /// Whole calendar days, never negative.
    private static func days(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let count = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
        return max(0, count)
    }
}
