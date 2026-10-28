import Foundation
import Testing
import StoreKitTest
@testable import Offshoots

@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["HINDSIGHT_STOREKIT"] == "1"), .serialized)
struct HindsightStoreKitIntegrationTests {
    @Test(arguments: [false, true])
    func restoreReportsLatestVerificationAfterEarlierResolvedCheck(wasOwned: Bool) async throws {
        final class BundleToken {}
        let config = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-purchase", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: config)
        session.disableDialogs = true
        let source = HindsightTestEntitlementSource(snapshot: .init(
            verifiedProductIDs: wasOwned ? ReflectionEntitlement.acceptedProductIDs : [], hasVerificationFailure: false))
        let entitlement = ReflectionEntitlement(source: source)
        await entitlement.refresh()
        #expect(entitlement.hasResolvedOwnership)
        source.snapshot = .init(verifiedProductIDs: [], hasVerificationFailure: true)
        let purchase = ReflectionPurchase(entitlement: entitlement, featureName: "Hindsight")
        await purchase.restore()
        #expect(entitlement.isUnlocked == wasOwned)
        #expect(purchase.restoreMessage == "The purchase could not be verified. Try Restore Purchase again later.")
        source.snapshot = .init(verifiedProductIDs: wasOwned ? ReflectionEntitlement.acceptedProductIDs : [], hasVerificationFailure: false)
        await purchase.restore()
        #expect(purchase.restoreMessage == (wasOwned ? "Hindsight is unlocked." : "No earlier purchase was found."))
    }

    @Test func existingProductUnlocksCaptureRestoreAndRefundWithoutAModel() async throws {
        final class BundleToken {}
        let config = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-purchase", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: config)
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let entitlement = ReflectionEntitlement()
        await entitlement.start()
        let purchase = ReflectionPurchase(entitlement: entitlement, featureName: "Hindsight")
        let access = HindsightAccess(isEnabled: true, entitlement: entitlement, purchase: purchase)
        #expect(!access.canCapture)
        await purchase.loadProduct()
        guard case .ready = purchase.state else { Issue.record("Local product did not load"); return }
        _ = try await session.buyProduct(identifier: "com.geoffrey.silva.Offshoots.reflection")
        await entitlement.refresh()
        #expect(access.canCapture)
        #expect(!ReflectionCenter.make(arguments: []).canGenerate)
        let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = DecisionStore(saveURL: url)
        let d = Make.decision(); store.add(d)
        #expect(access.performSave(answer: .differentChoice) {
            store.resolveDecision(id: d.id, actual: .good, reflection: "Useful, but not for me.", hindsight: $0)
        })
        let restored = ReflectionEntitlement()
        let restorer = ReflectionPurchase(entitlement: restored, featureName: "Hindsight")
        await restorer.restore()
        #expect(restored.isUnlocked)
        #expect(restorer.restoreMessage == "Hindsight is unlocked.")
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        await purchase.loadProduct()
        if case .unavailable = purchase.state { } else { Issue.record("Expected unavailable products") }
        #expect(access.canCapture)
        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .appStoreSync)
        await purchase.restore()
        #expect(purchase.restoreMessage == "Restore did not finish. Try again.")
        #expect(access.canCapture)
        try await session.setSimulatedError(nil, forAPI: .appStoreSync)
        let uncertainSource = HindsightTestEntitlementSource(snapshot: .init(verifiedProductIDs: [], hasVerificationFailure: true))
        let uncertainOwnership = ReflectionEntitlement(source: uncertainSource)
        let uncertainRestore = ReflectionPurchase(entitlement: uncertainOwnership, featureName: "Hindsight")
        await uncertainRestore.restore()
        #expect(!uncertainOwnership.isUnlocked)
        #expect(uncertainRestore.restoreMessage == "The purchase could not be verified. Try Restore Purchase again later.")
        let transaction = try #require(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        for _ in 0..<200 where entitlement.isUnlocked {
            await entitlement.refresh()
            if entitlement.isUnlocked { try await Task.sleep(for: .milliseconds(10)) }
        }
        #expect(!access.canCapture)
        let pendingAnswer: HindsightAnswer? = .sameApproach
        #expect(!access.performSave(answer: pendingAnswer) {
            store.addRevisit(id: d.id, outcome: .bad, note: "Draft", hindsight: $0)
        })
        #expect(pendingAnswer == .sameApproach)
        #expect(store.decisions.first?.revisits.isEmpty == true)
        #expect(access.showsInsights(hasSavedAnswers: true))
        #expect(HindsightSummary.entries(from: store.decisions).first?.answer == .differentChoice)
        #expect(try DecisionStore.decode(DecisionStore.encode(store.decisions)).first?.hindsight == .differentChoice)
        store.waitForPendingSaves()
    }
}

@Suite struct RestoreFailureMessageTests {
    private enum FakeStoreError: Error { case noAccount, other }

    @Test func aMissingAppStoreAccountSaysToSignIn() {
        #expect(ReflectionPurchase.restoreFailureMessage(for: FakeStoreError.noAccount)
            == "Sign in to the App Store in Settings, then try again.")
    }

    @Test func otherFailuresKeepTheGenericMessage() {
        #expect(ReflectionPurchase.restoreFailureMessage(for: FakeStoreError.other)
            == "Restore did not finish. Try again.")
        #expect(ReflectionPurchase.restoreFailureMessage(for: URLError(.notConnectedToInternet))
            == "Restore did not finish. Try again.")
    }
}
