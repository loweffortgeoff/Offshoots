//
//  ReflectionGenerating.swift
//  Offshoots
//

import Foundation

/// The seam between the app and the model. `LiveReflectionService` is the real one;
/// `FakeReflectionGenerator` serves the simulator and the tests.
/// Every call is independent: no history, nothing saved.
protocol ReflectionGenerating {
    func patterns(digest: PatternsDigest) async throws -> PatternsOutput
    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput
    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput
    func cleanUp(note: String) async throws -> CleanedNote
}
