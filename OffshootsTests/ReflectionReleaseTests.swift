import Testing
@testable import Offshoots

@MainActor
struct ReflectionReleaseTests {
    @Test func debugFakeSupportsLocalEvaluation() {
        #if DEBUG
        #expect(ReflectionCenter.make(arguments: ["-ReflectionFake"]).canGenerate)
        #endif
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
