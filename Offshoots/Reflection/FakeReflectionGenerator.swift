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
            guard let snapshot = digest.snapshot else { return PatternsOutput() }
            let keys = snapshot.evidence.filter { $0.stage == .log }.map(\.key)
            return PatternsOutput(observations: keys.count >= 2 ? [ReflectionObservation(text: "Sample reading: these notes describe commitments made quickly.", evidenceKeys: keys)] : [])
        }
    }

    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput {
        try await respond {
            let summary = digest.snapshot?.decisions.first(where: { $0.id == digest.snapshot?.subjectID }).map(DecisionReflectionOutput.timeline) ?? "No recorded timeline."
            return DecisionReflectionOutput(summary: summary)
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
