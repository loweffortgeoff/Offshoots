//
//  LogDecisionIntent.swift
//  Offshoots
//

import AppIntents
import Foundation

/// "Log a Decision" in Shortcuts and Siri. The type name is stored by saved
/// shortcuts and donations: do not rename it.
struct LogDecisionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Decision"
    static let description = IntentDescription(
        "Logs a new decision in Offshoots with your predicted outcome and schedules a follow-up review reminder.",
        categoryName: "Decisions"
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    /// Optional in code so a blank title can ask again instead of failing
    @Parameter(title: "Title", requestValueDialog: "What decision are you making?")
    var title: String?

    @Parameter(title: "Expected Outcome", requestValueDialog: "How do you expect it to turn out?")
    var expected: DecisionOutcomeAppEnum

    @Parameter(title: "Category", default: .other)
    var category: DecisionCategoryAppEnum

    @Parameter(title: "Stakes", default: .medium)
    var stakes: DecisionStakesAppEnum

    @Parameter(title: "Review Date", description: "When should Offshoots remind you to review it?")
    var reviewDate: Date?

    @Parameter(title: "Note", description: "Optional context note saved only inside Offshoots.")
    var notes: String?

    @Dependency var service: ShortcutsService

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$title) expecting \(\.$expected)") {
            \.$category
            \.$stakes
            \.$reviewDate
            \.$notes
        }
    }

    init() {}

    /// For donations: only the habit, never the title or note
    init(category: DecisionCategory, stakes: DecisionStakes) {
        self.category = DecisionCategoryAppEnum(category)
        self.stakes = DecisionStakesAppEnum(stakes)
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<DecisionEntity> & ProvidesDialog {
        // Every check comes before the write: a value request re-runs perform()
        guard !service.isBlocked else { throw ShortcutsError.blocked }
        guard let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw $title.needsValueError("What decision are you making?")
        }
        let decision = try service.logDecision(
            title: title,
            expected: expected.model,
            category: category.model,
            stakes: stakes.model,
            reviewDate: reviewDate,
            notes: notes
        )
        return .result(value: DecisionEntity(decision, now: .now),
                       dialog: IntentDialog(ShortcutsDialog.logged(decision)))
    }
}
