import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionRequestControllerTests {
    private func makeStore() -> ReflectionHistoryStore {
        ReflectionHistoryStore(saveURL: URL.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json"))
    }
    private func decisions() -> [Decision] {
        [Make.decision(actual: .bad, notes: "Bought immediately"), Make.decision(actual: .bad, notes: "Agreed immediately")]
    }
    @Test func successSavesOnceAndFailurePreservesHistory() async {
        let history = makeStore()
        let values = decisions()
        let controller = ReflectionRequestController(generator: FakeReflectionGenerator(delay: .zero), history: history,
            canGenerate: { true }, currentDecisions: { values })
        controller.start(kind: .patterns, decisions: values)
        await controller.waitForCompletion()
        #expect(history.readings.count == 1)
        let failed = ReflectionRequestController(generator: FakeReflectionGenerator(delay: .zero, failure: .failed), history: history,
            canGenerate: { true }, currentDecisions: { values })
        failed.start(kind: .patterns, decisions: values)
        await failed.waitForCompletion()
        #expect(history.readings.count == 1)
        #expect(failed.error != nil)
    }
    @Test func cancellationAndSourceEditsPreventLateAppend() async {
        let history = makeStore()
        var values = decisions()
        let controller = ReflectionRequestController(generator: FakeReflectionGenerator(delay: .milliseconds(20)), history: history,
            canGenerate: { true }, currentDecisions: { values })
        controller.start(kind: .patterns, decisions: values)
        values[0].notes = "Changed"
        await controller.waitForCompletion()
        #expect(history.readings.isEmpty)
        controller.start(kind: .patterns, decisions: values)
        controller.cancel()
        await controller.waitForCompletion()
        #expect(history.readings.isEmpty)
    }
    @Test func entitlementLossAndEpochChangePreventAppend() async {
        for revoke in [true,false] {
            let history = makeStore()
            let values = decisions()
            var owned = true
            var epoch = UUID()
            let controller = ReflectionRequestController(generator: FakeReflectionGenerator(delay: .milliseconds(20)), history: history,
                canGenerate: { owned }, currentDecisions: { values }, epoch: { epoch })
            controller.start(kind: .patterns, decisions: values)
            if revoke { owned = false } else { epoch = UUID() }
            await controller.waitForCompletion()
            #expect(history.readings.isEmpty)
        }
    }
    @Test func deadlineAndSaveFailureAreVisibleWithoutLosingOldContent() async {
        let values = decisions()
        let history = makeStore()
        let timeout = ReflectionRequestController(generator: FakeReflectionGenerator(delay: .milliseconds(30)), history: history,
            canGenerate: { true }, currentDecisions: { values }, timeout: .milliseconds(1))
        timeout.start(kind: .patterns, decisions: values)
        await timeout.waitForCompletion()
        #expect(history.readings.isEmpty)
        #expect(timeout.error != nil)
        history.write = { _,_ in throw CocoaError(.fileWriteNoPermission) }
        let failed = ReflectionRequestController(generator: FakeReflectionGenerator(delay: .zero), history: history,
            canGenerate: { true }, currentDecisions: { values })
        failed.start(kind: .patterns, decisions: values)
        await failed.waitForCompletion()
        #expect(failed.unsaved != nil)
        #expect(failed.error != nil)
        #expect(history.readings.isEmpty)
    }
}
