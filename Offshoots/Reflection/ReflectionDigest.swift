//
//  ReflectionDigest.swift
//  Offshoots
//

import Foundation

/// One note, tagged with its decision's category and stakes.
struct NoteLine: Equatable {
    let category: String
    let stakes: String
    let text: String
}

/// Marked decisions, split by how the first result compared with the prediction. The prompt
/// reads this, never raw models. It leaves out the numbers the Insights cards already show.
struct PatternsDigest: Equatable {
    let resolvedCount: Int
    let worseCount: Int
    let asPredictedCount: Int
    let betterCount: Int
    /// Each list is newest first, cleaned, cut and capped. A decision's notes all go in its group.
    let worse: [NoteLine]
    let asPredicted: [NoteLine]
    let better: [NoteLine]

    var noteCount: Int { worse.count + asPredicted.count + better.count }
}

struct TimelineLine: Equatable {
    let daysAfterFirstOutcome: Int
    let outcome: String
    let note: String?
}

/// Another marked decision in the same category, for comparison.
struct HistoryLine: Equatable {
    let title: String
    let stakes: String
    /// -1 worse than predicted, 0 as predicted, 1 better (the sign of the first-result gap)
    let direction: Int
    let notes: String?
    let outcomeNote: String?
}

/// One marked decision, ready for a prompt. Equatable so a card can clear a stale result
/// when the decision changes.
struct DecisionDigest: Equatable {
    let title: String
    let category: String
    let stakes: String
    let expected: String
    let firstOutcome: String
    let daysToFirstOutcome: Int
    let timeline: [TimelineLine]
    /// The note written when the decision was logged
    let notes: String?
    /// The note written in Mark Outcome (`Decision.reflection`)
    let outcomeNote: String?
    /// Other marked decisions in the same category, newest first. Empty below
    /// `ReflectionDigestBuilder.minimumHistory`, so a single other decision is never a "pattern".
    var history: [HistoryLine] = []
    /// This decision's own direction, to split the history into same and different
    var direction: Int = 0

    var sameResult: [HistoryLine] { history.filter { $0.direction == direction } }
    var differentResult: [HistoryLine] { history.filter { $0.direction != direction } }

    /// False when the user wrote nothing: no log note, no outcome note, no revisit note.
    /// Then nothing can repeat, so the reflection skips that section.
    var hasWrittenText: Bool {
        notes != nil || outcomeNote != nil || timeline.contains { $0.note != nil }
    }
}

/// Past marked decisions in the category the user is logging now. Look Back reads this.
struct LookBackDigest: Equatable {
    let category: String
    /// Newest first, capped. Never fewer than `ReflectionDigestBuilder.minimumHistory`.
    /// The prompt reads this.
    let history: [HistoryLine]
    /// Every marked decision in the category, not capped. The headline, the count line and
    /// the bars read this; the model never sees it.
    let stats: LookBackStats

    var worse: [HistoryLine] { history.filter { $0.direction < 0 } }
    var asPredicted: [HistoryLine] { history.filter { $0.direction == 0 } }
    var better: [HistoryLine] { history.filter { $0.direction > 0 } }
    var hasNotes: Bool { history.contains { $0.notes != nil || $0.outcomeNote != nil } }
}

/// One marked decision: what the user predicted, and the first result they marked.
struct OutcomePair: Equatable {
    let expected: DecisionOutcome
    let actual: DecisionOutcome

    /// -1 worse than predicted, 0 as predicted, 1 better. The same sign as `predictionGap`.
    var direction: Int { (actual.numericValue - expected.numericValue).signum() }
}

/// Counts for the Look Back headline, count line and bars. Built in code, not by the model,
/// so the numbers are always right.
struct LookBackStats: Equatable {
    /// Below this many decisions there is no headline. Two or three decisions are not a lean.
    static let minimumForHeadline = 5

    let category: String
    let pairs: [OutcomePair]

    var total: Int { pairs.count }
    var worseCount: Int { pairs.filter { $0.direction < 0 }.count }
    var asPredictedCount: Int { pairs.filter { $0.direction == 0 }.count }
    var betterCount: Int { pairs.filter { $0.direction > 0 }.count }

    /// A group must hold more than half of the decisions and lead every other group by this
    /// many, so 7 better against 6 worse is not a lean.
    static let headlineMargin = 2

    /// Only for a clear lean. It counts directions and never averages them, so 6 worse and
    /// 7 better does not read as "as predicted".
    var headline: String? {
        guard total >= Self.minimumForHeadline else { return nil }
        let groups = [
            (count: betterCount, text: "Your \(category) decisions tend to beat your predictions"),
            (count: worseCount, text: "Your \(category) decisions tend to fall short of your predictions"),
            (count: asPredictedCount, text: "Your \(category) predictions tend to hold up"),
        ].sorted { $0.count > $1.count }
        guard groups[0].count * 2 > total, groups[0].count - groups[1].count >= Self.headlineMargin else { return nil }
        return groups[0].text
    }

    var summary: String {
        let parts = [
            worseCount == 0 ? nil : "\(worseCount) went worse than you predicted",
            asPredictedCount == 0 ? nil : "\(asPredictedCount) went as predicted",
            betterCount == 0 ? nil : "\(betterCount) went better",
        ].compactMap { $0 }
        let list = parts.count > 1 ? parts.dropLast().joined(separator: ", ") + " and " + parts.last! : parts.joined()
        return "Of the \(total) \(category) decisions you marked, \(list)."
    }

    /// How many decisions had each outcome, worst first. Outcomes with no decisions are left out.
    func counts(_ outcome: KeyPath<OutcomePair, DecisionOutcome>) -> [(outcome: DecisionOutcome, count: Int)] {
        DecisionOutcome.allCases.compactMap { level in
            let count = pairs.filter { $0[keyPath: outcome] == level }.count
            return count == 0 ? nil : (level, count)
        }
    }

    /// One plain line per row, for VoiceOver: "Expected: 2 Good, 1 Great."
    func spokenRow(_ title: String, _ outcome: KeyPath<OutcomePair, DecisionOutcome>) -> String {
        "\(title): " + counts(outcome).map { "\($0.count) \($0.outcome.shortLabel)" }.joined(separator: ", ") + "."
    }
}
