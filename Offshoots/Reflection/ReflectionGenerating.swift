//
//  ReflectionGenerating.swift
//  Offshoots
//

import Foundation

/// The seam between the app and the model. `LiveReflectionService` is the real one;
/// `FakeReflectionGenerator` serves the simulator and the tests.
/// Each provider call is independent. The request controller saves accepted readings.
protocol ReflectionGenerating {
    func patterns(digest: PatternsDigest) async throws -> PatternsOutput
    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput
    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput
    func cleanUp(note: String) async throws -> CleanedNote
    /// The records one reading may read. The saved reading keeps this exact snapshot.
    func snapshot(for kind: SavedReflection.Kind, decisions: [Decision]) async -> ReflectionSourceSnapshot
}

extension ReflectionGenerating {
    func snapshot(for kind: SavedReflection.Kind, decisions: [Decision]) async -> ReflectionSourceSnapshot {
        Self.defaultSnapshot(for: kind, decisions: decisions)
    }

    /// The byte-bounded selection. A decision reading reads only its own decision.
    static func defaultSnapshot(for kind: SavedReflection.Kind, decisions: [Decision]) -> ReflectionSourceSnapshot {
        switch kind {
        case .patterns: .capture(decisions: decisions, subjectID: nil)
        case .decision(let id): .capture(decisions: decisions.filter { $0.id == id }, subjectID: id)
        }
    }
}
