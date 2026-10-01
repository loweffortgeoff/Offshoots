//
//  ReflectionDigest.swift
//  Offshoots
//

import Foundation

/// How many marked decisions in a group, and how many matched the prediction exactly.
struct GroupLine: Equatable {
    let label: String
    let resolved: Int
    let exact: Int
}

/// A small, stable summary of all marked decisions. The prompt reads this, never raw models.
struct PatternsDigest: Equatable {
    let resolvedCount: Int
    /// Share of marked decisions whose latest rating is good or great
    let goodPercent: Int
    /// Measured against the first rating
    let accuracy: AccuracyBreakdown
    let optimism: OptimismBias?
    let trend: TrendResult
    let categories: [GroupLine]
    let stakes: [GroupLine]
    let revisitedCount: Int
    /// Decisions whose latest rating differs from the first
    let revisitsChangingOutcome: Int
    /// Newest first, each cleaned and cut
    let notes: [String]
}

struct TimelineLine: Equatable {
    let daysAfterFirstOutcome: Int
    let outcome: String
    let note: String?
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
}
