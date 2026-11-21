//
//  OpenDecisionIntents.swift
//  Offshoots
//

import AppIntents
import Foundation

/// Opens a decision from Spotlight or the Shortcuts "Open Decision" action,
/// through the same router as widget links and notification taps.
struct OpenDecisionIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Decision"
    static let description = IntentDescription("Opens a decision in Offshoots.", categoryName: "Decisions")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    /// iOS 18.6–25. Deprecated in iOS 26, where `supportedModes` takes over.
    static let openAppWhenRun: Bool = true
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Decision", requestValueDialog: "Which decision?")
    var target: DecisionEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouteDispatcher.shared.send(.decision(target.id))
        return .result()
    }
}

/// Opens the Ready to Review list.
struct OpenReadyToReviewIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Ready to Review"
    static let description = IntentDescription(
        "Opens the decisions that are ready to review in Offshoots.",
        categoryName: "Decisions"
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let isDiscoverable: Bool = true
    /// iOS 18.6–25. Deprecated in iOS 26, where `supportedModes` takes over.
    static let openAppWhenRun: Bool = true
    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    static var parameterSummary: some ParameterSummary {
        Summary("Open Ready to Review")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouteDispatcher.shared.send(.readyToReview)
        return .result()
    }
}
