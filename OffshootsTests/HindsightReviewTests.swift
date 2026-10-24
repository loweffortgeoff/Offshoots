import Foundation
import Testing
@testable import Offshoots

@MainActor
struct HindsightReviewTests {
    @Test func answerTogglesAndOutcomeCombinesWithoutChangingDenominator() {
        var a = Make.marked(.good, .bad); a.hindsight = .sameApproach
        var b = Make.marked(); b.hindsight = .differentChoice
        var c = Make.marked(); c.hindsight = .notSure
        let entries = HindsightSummary.entries(from: [a,b,c])
        var filter = HindsightReviewFilter()
        filter.toggle(.sameApproach)
        filter.outcome = .bad
        #expect(filter.apply(to: entries).map(\.decisionID) == [a.id])
        #expect(HindsightSummary.count(.differentChoice, in: entries) == 1)
        filter.toggle(.sameApproach)
        #expect(filter.answer == nil)
        #expect(filter.outcome == .bad)
        filter.toggle(.notSure)
        #expect(filter.apply(to: entries).isEmpty)
        filter.outcome = nil
        #expect(filter.apply(to: entries).map(\.decisionID) == [c.id])
        filter = HindsightReviewFilter()
        #expect(filter.apply(to: entries).count == 3)
    }

    @Test func savedDataKeepsReviewVisibleWithoutOwnership() {
        let locked = HindsightAccess(isEnabled: true, entitlement: nil, purchase: nil)
        #expect(locked.showsInsights(hasSavedAnswers: false))
        let disabled = HindsightAccess(isEnabled: false, entitlement: nil, purchase: nil)
        #expect(!disabled.showsInsights(hasSavedAnswers: false))
        #expect(disabled.showsInsights(hasSavedAnswers: true))
        #expect(!disabled.canCapture)
    }

    @Test func deletionAndReplacementRecomputeTheRecordedSet() {
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = DecisionStore(saveURL: url)
        var d = Make.marked(); d.hindsight = .notSure
        store.add(d)
        #expect(HindsightSummary.entries(from: store.decisions).count == 1)
        store.delete(d)
        #expect(HindsightSummary.entries(from: store.decisions).isEmpty)
        store.replaceAll(with: [d])
        #expect(HindsightSummary.entries(from: store.decisions).first?.answer == .notSure)
        store.replaceAll(with: [Make.marked()])
        #expect(HindsightSummary.entries(from: store.decisions).isEmpty)
        store.waitForPendingSaves()
    }
}
