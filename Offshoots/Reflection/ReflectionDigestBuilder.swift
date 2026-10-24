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
    static let historyLimit = 5
    static let minimumHistory = 2
    static let historyTitleLimit = 60

    static func patterns(from decisions: [Decision]) -> PatternsDigest {
        let marked = decisions.filter { $0.actual != nil }
        let worse = marked.filter { (AnalyticsEngine.predictionGap(for: $0) ?? 0) < 0 }
        let asPredicted = marked.filter { AnalyticsEngine.predictionGap(for: $0) == 0 }
        let better = marked.filter { (AnalyticsEngine.predictionGap(for: $0) ?? 0) > 0 }
        return PatternsDigest(
            snapshot: .capture(decisions: decisions, subjectID: nil),
            resolvedCount: marked.count,
            worseCount: worse.count,
            asPredictedCount: asPredicted.count,
            betterCount: better.count,
            worse: noteLines(in: worse),
            asPredicted: noteLines(in: asPredicted),
            better: noteLines(in: better)
        )
    }

    /// Nil until an outcome is marked. `others` may hold any decisions; only other marked
    /// decisions in the same category become history.
    static func decision(_ decision: Decision, among others: [Decision] = []) -> DecisionDigest? {
        guard let actual = decision.actual, let resolved = decision.resolvedDate else { return nil }
        return DecisionDigest(
            snapshot: .capture(decisions: [decision], subjectID: decision.id),
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
            outcomeNote: ReflectionText.clean(decision.reflection, limit: longNoteLimit),
            history: history(in: decision.category, from: others.filter { $0.id != decision.id }),
            direction: direction(of: decision)
        )
    }

    /// Marked decisions in one category, newest first and capped. Empty below `minimumHistory`.
    static func history(in category: DecisionCategory, from decisions: [Decision]) -> [HistoryLine] {
        let lines = decisions
            .filter { $0.category == category && $0.actual != nil }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(historyLimit)
            .map { decision in
                HistoryLine(
                    title: ReflectionText.clean(decision.title, limit: historyTitleLimit) ?? "Untitled",
                    stakes: decision.stakes.label,
                    direction: direction(of: decision),
                    notes: ReflectionText.clean(decision.notes, limit: noteLimit),
                    outcomeNote: ReflectionText.clean(decision.reflection, limit: noteLimit)
                )
            }
        return lines.count >= minimumHistory ? Array(lines) : []
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

    /// Nil below `minimumHistory` marked decisions in the category.
    static func lookBack(category: DecisionCategory, in decisions: [Decision]) -> LookBackDigest? {
        let history = history(in: category, from: decisions)
        guard !history.isEmpty else { return nil }
        let stats = LookBackStats.build(category: category, decisions: decisions)
        return LookBackDigest(category: stats.category, history: history, stats: stats)
    }

    private static func direction(of decision: Decision) -> Int {
        (AnalyticsEngine.predictionGap(for: decision) ?? 0).signum()
    }

    /// Whole calendar days, never negative.
    private static func days(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let count = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
        return max(0, count)
    }
}
