//
//  ShortcutsDonation.swift
//  Offshoots
//

import AppIntents

/// Tells Siri Suggestions about actions taken in the app's own screens; the
/// system donates only the intents it runs itself. Donations carry the habit
/// (category, stakes, outcome), never a title, note or decision, so nothing
/// personal shows in a suggestion and nothing goes stale when a decision is deleted.
enum ShortcutsDonation {
    static func loggedDecision(category: DecisionCategory, stakes: DecisionStakes) {
        let intent = LogDecisionIntent(category: category, stakes: stakes)
        Task { _ = try? await IntentDonationManager.shared.donate(intent: intent) }
    }

    static func recordedOutcome(_ outcome: DecisionOutcome) {
        let intent = RecordOutcomeIntent(outcome: outcome)
        Task { _ = try? await IntentDonationManager.shared.donate(intent: intent) }
    }
}
