//
//  ReflectionEligibility.swift
//  Offshoots
//

import Foundation

enum CleanUpStatus: Equatable {
    case tooShort
    case ok
    case tooLong
}

/// Decides which decisions and notes may produce Reflection output.
enum ReflectionEligibility {
    static let minimumResolvedForPatterns = 5
    static let minimumNoteWords = 3
    /// Keeps the prompt well inside the on-device model's context window
    static let maximumNoteCharacters = 1_500

    static func canShowPatterns(for decisions: [Decision]) -> Bool {
        AnalyticsEngine.markedCount(from: decisions) >= minimumResolvedForPatterns
    }

    /// A marked outcome, and something written or revisited to read.
    /// Note: `Decision.reflection` is the user's Mark Outcome note, not this feature.
    static func canReflect(on decision: Decision) -> Bool {
        guard decision.actual != nil else { return false }
        return hasText(decision.notes) || hasText(decision.reflection) || !decision.revisits.isEmpty
    }

    static func cleanUpStatus(_ text: String) -> CleanUpStatus {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= maximumNoteCharacters else { return .tooLong }
        let words = trimmed.split(whereSeparator: \.isWhitespace).count
        return words >= minimumNoteWords ? .ok : .tooShort
    }

    private static func hasText(_ text: String?) -> Bool {
        text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
