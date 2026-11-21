//
//  ShortcutsDialog.swift
//  Offshoots
//

import Foundation

/// What Siri says after each intent. Titles are spoken only after the phone is
/// unlocked (every intent requires authentication); notes never are.
enum ShortcutsDialog {
    static func logged(_ decision: Decision) -> LocalizedStringResource {
        let category = DecisionCategoryAppEnum(decision.category).label
        let date = decision.followUpDate.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted))
        return "Logged \"\(decision.title)\" in \(category). Review set for \(date)."
    }

    static func firstOutcome(_ decision: Decision) -> LocalizedStringResource {
        let actual = DecisionOutcomeAppEnum(decision.actual ?? decision.expected).label
        let expected = DecisionOutcomeAppEnum(decision.expected).label
        return "Recorded \(actual) for \"\(decision.title)\" (you expected \(expected))."
    }

    static func revisit(_ decision: Decision, outcome: DecisionOutcome) -> LocalizedStringResource {
        "Added revisit: \(DecisionOutcomeAppEnum(outcome).label) for \"\(decision.title)\"."
    }

    static func ready(_ decisions: [Decision]) -> LocalizedStringResource {
        switch decisions.count {
        case 0: "No decisions are ready to review right now."
        case 1: "1 decision is ready to review: \(decisions[0].title)."
        default: "\(decisions.count) decisions are ready to review, starting with \(decisions[0].title)."
        }
    }
}
