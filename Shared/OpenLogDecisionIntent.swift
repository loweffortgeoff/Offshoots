//
//  OpenLogDecisionIntent.swift
//  Shared by the app and the widget extension
//

import AppIntents
import Foundation

/// Internal navigation intent for the Control Center / Lock Screen / Action Button control.
/// `isDiscoverable = false` keeps it out of the Shortcuts app so it never collides with
/// the parameterized Shortcuts actions planned for Stop 2.
nonisolated struct OpenLogDecisionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Decision"
    static let openAppWhenRun: Bool = true
    static let isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRouteDispatcher.shared.send(.log)
        }
        return .result()
    }
}
