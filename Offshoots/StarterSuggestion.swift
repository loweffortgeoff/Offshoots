//
//  StarterSuggestion.swift
//  Offshoots
//

import Foundation

/// A small example decision for new users. Short reviews build a sample fast
struct StarterSuggestion: Identifiable, Equatable {
    let title: String
    let category: DecisionCategory

    var id: String { title }

    /// One per category, in the order the card offers them
    static let all: [StarterSuggestion] = [
        StarterSuggestion(title: "Reply to that email today, not Friday", category: .work),
        StarterSuggestion(title: "Buy the cheaper headphones", category: .money),
        StarterSuggestion(title: "Skip the gym and rest tonight", category: .health),
        StarterSuggestion(title: "Text an old friend first", category: .relationships),
        StarterSuggestion(title: "Leave the dishes until morning", category: .home),
        StarterSuggestion(title: "Try the new lunch spot", category: .other),
    ]

    /// The card goes away once the user has logged this many decisions
    static let cutoff = 5

    /// The first three examples whose title the user has not logged, or none at the cutoff
    static func available(given decisions: [Decision]) -> [StarterSuggestion] {
        guard decisions.count < cutoff else { return [] }
        let loggedTitles = Set(decisions.map(\.title))
        return Array(all.filter { !loggedTitles.contains($0.title) }.prefix(3))
    }
}
