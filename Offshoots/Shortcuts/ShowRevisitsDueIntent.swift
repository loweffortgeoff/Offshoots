//
//  ShowRevisitsDueIntent.swift
//  Offshoots
//

import AppIntents
import Foundation

/// "Show Decisions Ready to Review". Read-only, so a re-run is harmless.
/// Do not rename the type.
struct ShowRevisitsDueIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Decisions Ready to Review"
    static let description = IntentDescription(
        "Lists your Offshoots decisions that are currently ready for review or a revisit.",
        categoryName: "Decisions"
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Category", description: "Only show decisions in this category.")
    var category: DecisionCategoryAppEnum?

    @Dependency var service: ShortcutsService

    static var parameterSummary: some ParameterSummary {
        Summary("Show decisions ready to review") {
            \.$category
        }
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<[DecisionEntity]> & ProvidesDialog {
        let ready = service.readyForReview(category: category?.model)
        let now = Date.now
        return .result(value: ready.map { DecisionEntity($0, now: now) },
                       dialog: IntentDialog(ShortcutsDialog.ready(ready)))
    }
}
