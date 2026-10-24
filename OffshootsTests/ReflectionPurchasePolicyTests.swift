import Testing
@testable import Offshoots

@MainActor
struct ReflectionPurchasePolicyTests {
    @Test func unavailableModelCannotStartPurchaseButHistoryIsReadable() async {
        let purchase = ReflectionPurchase(entitlement: ReflectionEntitlement(), canPurchase: { false })
        #expect(await purchase.buy() == false)
        if case .failed(let message) = purchase.state { #expect(message.contains("available")) }
        else { Issue.record("Unavailable model must explain why purchase cannot proceed") }
        let center = ReflectionCenter(generator: FakeReflectionGenerator(), availabilityProvider: { .unsupported })
        #expect(center.canReadHistory)
        #expect(!center.canGenerate)
    }
}
