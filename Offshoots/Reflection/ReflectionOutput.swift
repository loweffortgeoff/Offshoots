//
//  ReflectionOutput.swift
//  Offshoots
//

import Foundation

/// What a surface shows. Plain values with no SDK types, so the UI and tests never touch the model.
struct PatternsOutput: Equatable {
    var observations: [String]
}

struct DecisionReflectionOutput: Equatable {
    var summary: String
    var repeating: [String]
    var nextPrompt: String
    /// What this decision shares with others in its category that went the same way.
    /// Empty when none did.
    var echo: String = ""
}

struct CleanedNote: Equatable {
    var text: String
}

enum ReflectionError: Error, Equatable {
    /// The model answered, but nothing usable came back
    case emptyOutput
    case failed

    var userMessage: String {
        switch self {
        case .emptyOutput: "Nothing useful came back. Try again."
        case .failed: "Reflection could not finish. Try again."
        }
    }
}

// MARK: - Validation
// Live output passes through `validated()` so a blank card can never reach the screen.

extension PatternsOutput {
    /// Fewer words than this is a fragment, not an observation
    static let minimumWords = 3

    func validated() throws -> PatternsOutput {
        let lines = ReflectionText.uniqueLines(observations, limit: 400)
            .filter { $0.split(whereSeparator: \.isWhitespace).count >= Self.minimumWords }
        guard !lines.isEmpty else { throw ReflectionError.emptyOutput }
        return PatternsOutput(observations: lines)
    }
}

extension DecisionReflectionOutput {
    /// The summary is required. A missing next prompt just hides that line.
    func validated() throws -> DecisionReflectionOutput {
        guard let summary = ReflectionText.clean(summary, limit: 600) else { throw ReflectionError.emptyOutput }
        return DecisionReflectionOutput(
            summary: summary,
            repeating: ReflectionText.uniqueLines(repeating, limit: 400),
            nextPrompt: ReflectionText.clean(nextPrompt, limit: 300) ?? "",
            echo: ReflectionText.clean(echo, limit: 400) ?? ""
        )
    }
}

extension CleanedNote {
    func validated() throws -> CleanedNote {
        // Keeps the model's own line breaks; only the edges are trimmed
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ReflectionError.emptyOutput }
        return CleanedNote(text: trimmed)
    }
}
