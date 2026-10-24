import Testing
@testable import Offshoots

@MainActor
struct ReflectionReleaseTests {
    @Test func debugFakeSupportsLocalEvaluation() {
        #if DEBUG
        #expect(ReflectionCenter.make(arguments: ["-ReflectionFake"]).canGenerate)
        #endif
    }
    @Test func debugLockedFakeAllowsPaywallInspectionWithoutUnlocking() {
        #if DEBUG
        let center = ReflectionCenter.make(arguments: ["-ReflectionFakeLocked"])
        #expect(center.gate == .paywalled)
        #expect(center.purchase != nil)
        #expect(!center.isUnlocked)
        #endif
    }
    @Test func unsupportedPaidFactoryStillProvidesOwnershipAndRestore() {
        let center = ReflectionCenter.makePaid(generator: FakeReflectionGenerator(), availabilityProvider: { .unsupported })
        #expect(center.entitlement != nil)
        #expect(center.purchase != nil)
        #expect(center.gate == .hidden)
        #expect(center.canReadHistory)
    }
    /// Catches a release factory that creates StoreKit or exposes the paid package in 2.0.
    @Test func productionLaunchHasNoPaidEntryPoint() {
        let center = ReflectionCenter.make(arguments: [])
        #expect(center.gate == .hidden)
        #expect(center.purchase == nil)
        #expect(center.entitlement == nil)
        #expect(!center.isUnlocked)
    }
}
