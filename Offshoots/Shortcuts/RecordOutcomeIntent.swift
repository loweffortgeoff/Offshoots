//
//  RecordOutcomeIntent.swift
//  Offshoots
//

import AppIntents
import Foundation

/// "Record Outcome": the first outcome on a pending decision, or a revisit on a
/// marked one. Never captures a Hindsight answer. Do not rename the type.
struct RecordOutcomeIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Outcome"
    static let description = IntentDescription(
        "Records how a decision actually turned out, or adds a new revisit rating to an already-marked decision.",
        categoryName: "Decisions"
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Decision", requestValueDialog: "Which decision?")
    var decision: DecisionEntity

    @Parameter(title: "Outcome", requestValueDialog: "How did it turn out?")
    var outcome: DecisionOutcomeAppEnum

    @Parameter(title: "Note", description: "Optional note about what happened.")
    var note: String?

    @Parameter(title: "Next Revisit", description: "Optional date to revisit this decision again.")
    var nextRevisitDate: Date?

    @Dependency var service: ShortcutsService

    static var parameterSummary: some ParameterSummary {
        Summary("Record \(\.$outcome) for \(\.$decision)") {
            \.$note
            \.$nextRevisitDate
        }
    }

    init() {}

    /// For donations: the outcome only, never the decision or a note
    init(outcome: DecisionOutcome) {
        self.outcome = DecisionOutcomeAppEnum(outcome)
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<DecisionEntity> & ProvidesDialog {
        let result = try service.recordOutcome(
            decisionID: decision.id,
            outcome: outcome.model,
            note: note,
            nextRevisitDate: nextRevisitDate
        )
        switch result {
        case .firstOutcome(let saved):
            return .result(value: DecisionEntity(saved, now: .now),
                           dialog: IntentDialog(ShortcutsDialog.firstOutcome(saved)))
        case .revisit(let saved):
            return .result(value: DecisionEntity(saved, now: .now),
                           dialog: IntentDialog(ShortcutsDialog.revisit(saved, outcome: outcome.model)))
        }
    }
}
