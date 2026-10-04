import Testing
@testable import Offshoots

@MainActor
struct ReflectionGateTests {
    @Test func unsupportedIsHiddenWhetherOrNotUnlocked() {
        #expect(ReflectionGate.state(availability: .unsupported, isUnlocked: true) == .hidden)
        #expect(ReflectionGate.state(availability: .unsupported, isUnlocked: false) == .hidden)
    }

    @Test func notReadyKeepsItsReasonWhetherOrNotUnlocked() {
        let availability = ModelAvailability.notReady(reason: "Getting ready")
        #expect(ReflectionGate.state(availability: availability, isUnlocked: true) == .notReady(reason: "Getting ready"))
        #expect(ReflectionGate.state(availability: availability, isUnlocked: false) == .notReady(reason: "Getting ready"))
    }

    @Test func availableAndLockedIsPaywalled() {
        #expect(ReflectionGate.state(availability: .available, isUnlocked: false) == .paywalled)
    }

    @Test func availableAndUnlockedIsEnabled() {
        #expect(ReflectionGate.state(availability: .available, isUnlocked: true) == .enabled)
    }
}
