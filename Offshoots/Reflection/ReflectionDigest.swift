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
