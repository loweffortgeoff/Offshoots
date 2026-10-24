import Foundation
import Testing
@testable import Offshoots

@MainActor
struct HindsightCaptureTests {
    @Test func repeatedFirstReviewDoesNotOverwriteRecordedHistory() throws {
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = DecisionStore(saveURL: url)
        var d = Make.marked(.good, .bad)
        d.hindsight = .differentApproach
        d.reflection = "Original account"
        store.add(d)
        store.resolveDecision(id: d.id, actual: .good, reflection: "Stale form", hindsight: .sameApproach)
        #expect(store.decisions.first == d)
        store.waitForPendingSaves()
    }

    @Test(arguments: HindsightAnswer.allCases)
    func capturePreservesFirstAnswerAndNewUnansweredRevisit(answer: HindsightAnswer) async throws {
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = DecisionStore(saveURL: url)
        let source = HindsightTestEntitlementSource(snapshot: .init(verifiedProductIDs: ReflectionEntitlement.acceptedProductIDs, hasVerificationFailure: false))
        let ownership = ReflectionEntitlement(source: source)
        await ownership.refresh()
        let access = HindsightAccess(isEnabled: true, entitlement: ownership, purchase: nil)
        let d = Make.decision(); store.add(d)
        #expect(access.performSave(answer: answer) {
            store.resolveDecision(id: d.id, actual: .bad, reflection: "My own note", hindsight: $0)
        })
        store.addRevisit(id: d.id, outcome: .good, note: "No new answer")
        #expect(store.decisions.first?.hindsight == answer)
        #expect(store.decisions.first?.revisits.last?.hindsight == nil)
        store.delete(d)
        access.performSave(answer: answer) { store.addRevisit(id: d.id, outcome: .good, hindsight: $0) }
        #expect(store.decisions.isEmpty)
        store.waitForPendingSaves()
    }
}
