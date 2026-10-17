import Testing
@testable import Offshoots

@MainActor
struct ReflectionReleaseTests {
    /// Catches a release factory that creates StoreKit or exposes the paid package in 2.0.
    @Test(arguments: [[], ["-ReflectionFake"], ["-ReflectionUnlockOnly"]])
    func productionLaunchHasNoPaidEntryPoint(arguments: [String]) {
        let center = ReflectionCenter.make(arguments: arguments)
        #expect(center.gate == .hidden)
        #expect(center.purchase == nil)
        #expect(center.entitlement == nil)
        #expect(!center.isUnlocked)
    }
}
