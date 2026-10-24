import Foundation
import Testing
import StoreKitTest
@testable import Offshoots

/// Explicit local StoreKit checks; never a sandbox or physical-device acceptance claim.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["REFLECTION_STOREKIT"] == "1"), .serialized)
struct ReflectionStoreKitIntegrationTests {
    @Test func oneTimePurchaseRestoreAndRefund() async throws {
        final class BundleToken {}
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-purchase", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let entitlement = ReflectionEntitlement()
        await entitlement.start()
        let purchase = ReflectionPurchase(entitlement: entitlement)
        await purchase.loadProduct()
        guard case .ready = purchase.state else { Issue.record("Local StoreKit product did not load"); return }
        print("STOREKIT product loaded; creating local test transaction")
        _ = try await session.buyProduct(identifier: "com.geoffrey.silva.Offshoots.reflection")
        await entitlement.refresh()
        print("STOREKIT local transaction created")
        #expect(entitlement.isUnlocked)
        let restored = ReflectionEntitlement()
        let restorer = ReflectionPurchase(entitlement: restored)
        print("STOREKIT starting restore")
        await restorer.restore()
        print("STOREKIT restore returned")
        #expect(restored.isUnlocked)
        #expect(restorer.restoreMessage == "Reflection is unlocked.")
        let transaction = try #require(session.allTransactions().first)
        print("STOREKIT starting refund")
        try session.refundTransaction(identifier: transaction.identifier)
        // StoreKit delivers revocation asynchronously after the synchronous test-session call.
        for _ in 0..<200 where entitlement.isUnlocked {
            await entitlement.refresh()
            if entitlement.isUnlocked { try await Task.sleep(for: .milliseconds(10)) }
        }
        #expect(!entitlement.isUnlocked)
    }
}
