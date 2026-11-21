//
//  OffshootsShortcuts.swift
//  Offshoots
//

import AppIntents

/// Siri phrases that work right after install. Shipped phrases are a contract:
/// add new ones, do not rename or remove them.
struct OffshootsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDecisionIntent(),
            phrases: [
                "Log a decision in \(.applicationName)",
                "Add a decision in \(.applicationName)"
            ],
            shortTitle: "Log Decision",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: RecordOutcomeIntent(),
            phrases: [
                "Record an outcome in \(.applicationName)",
                "Review a decision in \(.applicationName)"
            ],
            shortTitle: "Record Outcome",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: ShowRevisitsDueIntent(),
            phrases: [
                "Show decisions ready to review in \(.applicationName)",
                "What decisions are ready to review in \(.applicationName)"
            ],
            shortTitle: "Ready to Review",
            systemImageName: "bell.badge"
        )
    }
}
