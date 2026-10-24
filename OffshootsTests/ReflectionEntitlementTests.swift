//
//  ReflectionEntitlementTests.swift
//  OffshootsTests
//

import Testing
@testable import Offshoots

/// A source the test drives by hand.
private final class FakeEntitlementSource: ReflectionEntitlementSource {
    var current: Set<String>
    private var continuation: AsyncStream<EntitlementSnapshot>.Continuation?

    init(current: Set<String> = []) { self.current = current }

    func currentSnapshot() async -> EntitlementSnapshot { .init(verifiedProductIDs: current, hasVerificationFailure: false) }

    func updates() -> AsyncStream<EntitlementSnapshot> {
        AsyncStream { continuation = $0 }
    }

    func push(_ ids: Set<String>) {
        current = ids
        continuation?.yield(.init(verifiedProductIDs: ids, hasVerificationFailure: false))
    }

    func finish() { continuation?.finish() }
}

@MainActor
struct ReflectionEntitlementTests {
    private let oneTime = "com.example.reflection"
    private let subscription = "com.example.reflection.monthly"

    @Test func anyAcceptedProductUnlocks() {
        #expect(ReflectionEntitlement.unlocks(entitled: [oneTime], accepted: [oneTime, subscription]))
        #expect(ReflectionEntitlement.unlocks(entitled: [subscription], accepted: [oneTime, subscription]))
    }

    @Test func otherProductsDoNotUnlock() {
        #expect(!ReflectionEntitlement.unlocks(entitled: ["com.example.other"], accepted: [oneTime]))
        #expect(!ReflectionEntitlement.unlocks(entitled: [], accepted: [oneTime]))
    }

    @Test func refreshReadsWhatIsAlreadyOwned() async {
        let entitlement = ReflectionEntitlement(source: FakeEntitlementSource(current: [oneTime]), accepted: [oneTime])
        await entitlement.refresh()
        #expect(entitlement.isUnlocked)
    }

    @Test func aPurchaseDuringTheSessionUnlocksWithoutARelaunch() async {
        let source = FakeEntitlementSource()
        let entitlement = ReflectionEntitlement(source: source, accepted: [oneTime])
        await entitlement.refresh()
        #expect(!entitlement.isUnlocked)

        let listening = entitlement.listen()
        source.push([oneTime])
        source.finish()
        await listening.value
        #expect(entitlement.isUnlocked)
    }

    @Test func aRefundLocksItAgain() async {
        let source = FakeEntitlementSource(current: [oneTime])
        let entitlement = ReflectionEntitlement(source: source, accepted: [oneTime])
        await entitlement.refresh()
        #expect(entitlement.isUnlocked)

        let listening = entitlement.listen()
        source.push([])
        source.finish()
        await listening.value
        #expect(!entitlement.isUnlocked)
    }

    @Test func aLaterSubscriptionKeepsTheOneTimeBuyerUnlocked() async {
        // The accepted list holds both, so the old purchase still counts
        let entitlement = ReflectionEntitlement(source: FakeEntitlementSource(current: [oneTime]), accepted: [oneTime, subscription])
        await entitlement.refresh()
        #expect(entitlement.isUnlocked)
    }

    @Test func theShippedListAcceptsTheOneTimeProduct() {
        #expect(ReflectionEntitlement.acceptedProductIDs.contains("com.geoffrey.silva.Offshoots.reflection"))
    }
}
