import Foundation
import Testing
@testable import Offshoots

/// Ignores task cancellation until the test explicitly drains it.
@MainActor
private final class UncooperativeReflectionGenerator: ReflectionGenerating {
    var calls = 0
    private var pending: [CheckedContinuation<Void,Never>] = []
    private func suspend() async {
        calls += 1
        await withCheckedContinuation { pending.append($0) }
    }
    func drain() { let values = pending; pending = []; values.forEach { $0.resume() } }
    func patterns(digest: PatternsDigest) async throws -> PatternsOutput { await suspend(); return PatternsOutput() }
    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput { await suspend(); return DecisionReflectionOutput(summary: "Done") }
    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput { await suspend(); return LookBackOutput(stats: digest.stats, lines: []) }
    func cleanUp(note: String) async throws -> CleanedNote { await suspend(); return CleanedNote(text: note) }
}

@MainActor
struct ReflectionProviderCoordinatorTests {
    @Test func twoControllersShareOccupancyAfterCancellation() async {
        let base = UncooperativeReflectionGenerator()
        let provider = ReflectionProviderCoordinator(base: base)
        let history = ReflectionHistoryStore(saveURL: URL.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let values = [Make.decision(actual: .good, notes: "One"), Make.decision(actual: .bad, notes: "Two")]
        let first = ReflectionRequestController(generator: provider, history: history, canGenerate: { true }, currentDecisions: { values })
        let second = ReflectionRequestController(generator: provider, history: history, canGenerate: { true }, currentDecisions: { values })
        first.start(kind: .patterns, decisions: values)
        for _ in 0..<100 where base.calls == 0 { await Task.yield() }
        #expect(base.calls == 1)
        first.cancel()
        second.start(kind: .patterns, decisions: values)
        await second.waitForCompletion()
        #expect(base.calls == 1)
        #expect(second.error != nil)
        #expect(provider.isBusy)
        base.drain()
        await first.waitForCompletion()
        #expect(!provider.isBusy)
        #expect(history.readings.isEmpty)
    }
    @Test func cleanupRetriesCannotStartProvidersWhileTimedOutCallDrains() async throws {
        let base = UncooperativeReflectionGenerator()
        let provider = ReflectionProviderCoordinator(base: base)
        let run = ReflectionRun<CleanedNote>(timeout: .milliseconds(1))
        let first = run.start { try await provider.cleanUp(note: "Original note stays") }
        for _ in 0..<100 where base.calls == 0 { await Task.yield() }
        try await Task.sleep(for: .milliseconds(10))
        for _ in 0..<3 {
            await run.start { try await provider.cleanUp(note: "Another request") }.value
        }
        #expect(base.calls == 1)
        #expect(provider.isBusy)
        base.drain()
        await first.value
        #expect(!provider.isBusy)
    }
}
