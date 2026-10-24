//
//  ReflectionOutput.swift
//  Offshoots
//

import Foundation

/// What a surface shows. Plain values with no SDK types, so the UI and tests never touch the model.
/// One model sentence about one result group, with a fixed label from code. The label names
/// the group, so the sentence does not have to.
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
    case insufficientEvidence
    case instructionLikeInput
    case providerBusy
    case failed

    var userMessage: String {
        switch self {
        case .providerBusy: "Another reflection is still finishing. Wait a moment before trying again."
        case .instructionLikeInput: "Reflection could not safely read this note. Your original note is unchanged."
        case .insufficientEvidence: "These records do not support a clear connection yet. Add notes or return after more outcomes."
        case .emptyOutput: "Nothing useful came back. Try again."
        case .failed: "Reflection could not finish. Try again."
        }
    }
}

// MARK: - Validation
// Live output passes through `validated()` so a blank card can never reach the screen.

extension LookBackOutput {
    /// The count line always shows, so empty observations are not an error
    func validated() -> LookBackOutput {
        LookBackOutput(stats: stats, lines: ReflectionGroupLine.validated(lines))
    }

    /// The model on a phone can copy an input line back (seen 2026-10-14). With the leftovers
    /// stripped, that sentence is only a decision title, so it says nothing and is dropped.
    func droppingTitleCopies(_ titles: [String]) -> LookBackOutput {
        let copies = Set(titles.map(Self.titleKey))
        return LookBackOutput(stats: stats, lines: lines.filter { !copies.contains(Self.titleKey($0.text)) })
    }

    private static func titleKey(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ".")))
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
