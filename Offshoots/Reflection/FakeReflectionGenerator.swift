//
//  FakeReflectionGenerator.swift
//  Offshoots
//

#if DEBUG
import Foundation

/// Canned output for the simulator, which has no model, and for tests.
/// The launch flag `-ReflectionFake` turns it on (see `ReflectionCenter`).
struct FakeReflectionGenerator: ReflectionGenerating {
    var delay: Duration = .milliseconds(600)
    var failure: ReflectionError?

    func patterns(digest: PatternsDigest) async throws -> PatternsOutput {
        try await respond {
            PatternsOutput(lines: [
                ReflectionGroupLine(label: ReflectionGroupLine.worseLabel, text: "Made in a hurry, often before a deadline."),
                ReflectionGroupLine(label: ReflectionGroupLine.betterLabel, text: "Choices you dreaded, then prepared for."),
            ])
        }
    }

    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput {
        try await respond {
            DecisionReflectionOutput(
                summary: "\(digest.title) started as \(digest.firstOutcome) and has held steady since.",
                repeating: digest.hasWrittenText ? ["The same worry shows up in each note.", "Your rating moved once, then settled."] : [],
                nextPrompt: "What would make you rate this differently at the next revisit?",
                echo: digest.sameResult.isEmpty ? "" : "Like the gym plan, this one was decided on the spot."
            )
        }
    }

    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput {
        try await respond {
            LookBackOutput(stats: digest.stats, lines: [
                ReflectionGroupLine(label: ReflectionGroupLine.worseLabel, text: "Decided on the spot."),
                ReflectionGroupLine(label: ReflectionGroupLine.betterLabel, text: "Planned over several weeks."),
            ])
        }
    }

    func cleanUp(note: String) async throws -> CleanedNote {
        try await respond { CleanedNote(text: "Cleaned up: " + note.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private func respond<T>(_ make: () -> T) async throws -> T {
        try await Task.sleep(for: delay)
        if let failure { throw failure }
        return make()
    }
}
#endif
