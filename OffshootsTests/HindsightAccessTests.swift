import Foundation
import Testing
@testable import Offshoots

@MainActor
struct HindsightAccessTests {
    private let productID = "com.geoffrey.silva.Offshoots.reflection"

    @Test func verificationUncertaintyPreservesOnlyKnownOwnership() async {
        let source = HindsightTestEntitlementSource(snapshot: .init(verifiedProductIDs: [], hasVerificationFailure: true))
        let entitlement = ReflectionEntitlement(source: source)
        await entitlement.refresh()
        #expect(!entitlement.isUnlocked)
        #expect(!entitlement.hasResolvedOwnership)
        source.snapshot = .init(verifiedProductIDs: [productID], hasVerificationFailure: false)
        await entitlement.refresh()
        #expect(entitlement.isUnlocked)
        source.snapshot = .init(verifiedProductIDs: [], hasVerificationFailure: true)
        await entitlement.refresh()
        #expect(entitlement.isUnlocked)
        source.snapshot = .init(verifiedProductIDs: [], revokedProductIDs: [productID], hasVerificationFailure: true)
        await entitlement.refresh()
        #expect(!entitlement.isUnlocked)
        #expect(entitlement.hasResolvedOwnership)
    }

    @Test func cleanEmptySnapshotRemovesOwnership() async {
        let source = HindsightTestEntitlementSource(snapshot: .init(verifiedProductIDs: [productID], hasVerificationFailure: false))
        let entitlement = ReflectionEntitlement(source: source)
        await entitlement.refresh()
        source.snapshot = .init(verifiedProductIDs: [], hasVerificationFailure: false)
        await entitlement.refresh()
        #expect(!entitlement.isUnlocked)
    }

    @Test func delayedRefreshCannotOverwriteNewerRevocation() async throws {
        let source = HindsightTestEntitlementSource(snapshot: .init(verifiedProductIDs: [productID], hasVerificationFailure: false))
        let entitlement = ReflectionEntitlement(source: source)
        await entitlement.refresh()
        let listener = entitlement.listen()
        source.delayNextRead = true
        let refresh = Task { await entitlement.refresh() }
        for _ in 0..<100 where source.pendingRead == nil { await Task.yield() }
        try #require(source.pendingRead != nil)
        source.push(.init(verifiedProductIDs: [], revokedProductIDs: [productID], hasVerificationFailure: false))
        source.finish()
        await listener.value
        source.resumeRead()
        await refresh.value
        #expect(!entitlement.isUnlocked)
    }

    @Test func startupSubscribesBeforeReadingSnapshot() async {
        let source = HindsightTestEntitlementSource()
        source.onRead = {
            source.push(.init(verifiedProductIDs: [productID], hasVerificationFailure: false))
            source.finish()
        }
        let entitlement = ReflectionEntitlement(source: source)
        await entitlement.start()
        for _ in 0..<100 where !entitlement.isUnlocked { await Task.yield() }
        #expect(entitlement.isUnlocked)
    }

    @Test func ownershipLossBlocksWholeSaveUntilAnswerClearedOrRestored() async throws {
        let source = HindsightTestEntitlementSource(snapshot: .init(verifiedProductIDs: [productID], hasVerificationFailure: false))
        let entitlement = ReflectionEntitlement(source: source)
        await entitlement.refresh()
        let access = HindsightAccess(isEnabled: true, entitlement: entitlement, purchase: nil)
        #expect(access.canCapture)
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = DecisionStore(saveURL: url)
        let d = Make.decision(); store.add(d)
        var answer: HindsightAnswer? = .differentApproach
        let note = "Spread the checks out."
        source.snapshot = .init(verifiedProductIDs: [], hasVerificationFailure: false)
        await entitlement.refresh()
        let save: (HindsightAnswer?) -> Void = {
            store.resolveDecision(id: d.id, actual: .bad, reflection: note, hindsight: $0)
        }
        #expect(!access.performSave(answer: answer, save: save))
        #expect(store.decisions.first?.actual == nil)
        #expect(answer == .differentApproach)
        answer = nil
        #expect(access.performSave(answer: answer, save: save))
        #expect(store.decisions.first?.reflection == note)
        source.snapshot = .init(verifiedProductIDs: [productID], hasVerificationFailure: false)
        await entitlement.refresh()
        #expect(access.performSave(answer: .differentApproach) {
            store.addRevisit(id: d.id, outcome: .neutral, note: note, hindsight: $0)
        })
        #expect(store.decisions.first?.revisits.last?.hindsight == .differentApproach)
        store.waitForPendingSaves()
    }

    @Test func disabledFactoryDoesNotCreatePurchaseOrExposeCapture() {
        let access = HindsightAccess.make(arguments: [], defaults: freshDefaults())
        #expect(!access.isEnabled)
        #expect(!access.canCapture)
        #expect(access.entitlement == nil)
        #expect(access.purchase == nil)
        #expect(!access.showsInsights(hasSavedAnswers: false))
        #expect(access.showsInsights(hasSavedAnswers: true))
        #expect(!ReflectionCenter.make(arguments: []).canGenerate)
    }

    @Test func lockedPreviewCannotBuy() async {
        #if DEBUG
        let access = HindsightAccess.make(arguments: ["-HindsightLocked"])
        #expect(access.isEnabled)
        #expect(!access.canCapture)
        #expect(await access.purchase?.buy() == false)
        #endif
    }

    @Test func storeKitArgumentPersistsUntilTurnedOff() {
        #if DEBUG
        let defaults = freshDefaults()
        #expect(HindsightAccess.make(arguments: ["-HindsightStoreKit"], defaults: defaults).isEnabled)
        #expect(HindsightAccess.make(arguments: [], defaults: defaults).isEnabled)
        #expect(!HindsightAccess.make(arguments: ["-HindsightStoreKitOff"], defaults: defaults).isEnabled)
        #expect(!HindsightAccess.make(arguments: [], defaults: defaults).isEnabled)
        #endif
    }

    private func freshDefaults() -> UserDefaults {
        let name = "HindsightAccessTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
