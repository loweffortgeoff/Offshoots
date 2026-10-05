//
//  ReflectionOutput.swift
//  Offshoots
//

import Foundation

/// What a surface shows. Plain values with no SDK types, so the UI and tests never touch the model.
struct PatternsOutput: Equatable {
    /// At most one per result group, so the label is unique
    var lines: [ReflectionGroupLine]
}

struct DecisionReflectionOutput: Equatable {
    var summary: String
    var repeating: [String]
    var nextPrompt: String
    /// What this decision shares with others in its category that went the same way.
    /// Empty when none did.
    var echo: String = ""
}

/// One model sentence about one result group, with a fixed label from code. The label names
/// the group, so the sentence does not have to.
struct ReflectionGroupLine: Equatable {
    var label: String
    var text: String

    static let worseLabel = "Went worse"
    static let asPredictedLabel = "Went as predicted"
    static let betterLabel = "Went better"
}

/// The headline, count line and bars come from `stats`; the lines come from the model and
/// may be empty.
struct LookBackOutput: Equatable {
    var stats: LookBackStats
    /// At most one per result group, so the label is unique
    var lines: [ReflectionGroupLine]
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
        let kept = ReflectionGroupLine.validated(lines)
        guard !kept.isEmpty else { throw ReflectionError.emptyOutput }
        return PatternsOutput(lines: kept)
    }
}

extension LookBackOutput {
    /// The count line always shows, so empty observations are not an error
    func validated() -> LookBackOutput {
        LookBackOutput(stats: stats, lines: ReflectionGroupLine.validated(lines))
    }
}

extension ReflectionGroupLine {
    /// Cleans each sentence. Drops blanks, fragments and a sentence that repeats an earlier one.
    static func validated(_ lines: [ReflectionGroupLine]) -> [ReflectionGroupLine] {
        var seen = Set<String>()
        return lines.compactMap { line in
            guard let text = ReflectionText.clean(line.text, limit: 400).map(ReflectionText.dropGroupOpening),
                  text.split(whereSeparator: \.isWhitespace).count >= PatternsOutput.minimumWords,
                  seen.insert(text).inserted
            else { return nil }
            return ReflectionGroupLine(label: line.label, text: text)
        }
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
