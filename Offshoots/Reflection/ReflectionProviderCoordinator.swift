import Foundation
import Observation

/// One shared owner per ReflectionCenter. Cancellation never releases an occupied provider early.
@MainActor @Observable
final class ReflectionProviderCoordinator: ReflectionGenerating {
    private(set) var isBusy = false
    @ObservationIgnored private let base: any ReflectionGenerating
    init(base: any ReflectionGenerating) { self.base = base }

    private func perform<Value>(_ work: @MainActor () async throws -> Value) async throws -> Value {
        try Task.checkCancellation()
        guard !isBusy else { throw ReflectionError.providerBusy }
        isBusy = true
        defer { isBusy = false }
        return try await work()
    }
    func patterns(digest: PatternsDigest) async throws -> PatternsOutput {
        try await perform { try await base.patterns(digest: digest) }
    }
    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput {
        try await perform { try await base.reflect(on: digest) }
    }
    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput {
        try await perform { try await base.lookBack(digest: digest) }
    }
    func cleanUp(note: String) async throws -> CleanedNote {
        try await perform { try await base.cleanUp(note: note) }
    }
}
