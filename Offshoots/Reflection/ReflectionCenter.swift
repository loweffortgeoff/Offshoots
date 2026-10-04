//
//  ReflectionCenter.swift
//  Offshoots
//

import Foundation
import Observation

/// One place that knows whether Reflection can run: what the device supports, whether the
/// user unlocked it, and which generator to use. Views read `gate` and nothing else.
@Observable
final class ReflectionCenter {
    private(set) var availability: ModelAvailability
    /// Debug launch flags only. A real unlock comes from `entitlement`.
    @ObservationIgnored private let forceUnlocked: Bool
    @ObservationIgnored let entitlement: ReflectionEntitlement?
    /// Nil only in the debug branches, where the gate is never `paywalled`
    @ObservationIgnored let purchase: ReflectionPurchase?
    @ObservationIgnored let generator: any ReflectionGenerating
    @ObservationIgnored private let availabilityProvider: () -> ModelAvailability

    /// Reads the observable entitlement, so a purchase or a refund updates every surface
    var isUnlocked: Bool {
        forceUnlocked || entitlement?.isUnlocked == true
    }

    var gate: ReflectionSurfaceState {
        ReflectionGate.state(availability: availability, isUnlocked: isUnlocked)
    }

    init(
        generator: any ReflectionGenerating,
        availabilityProvider: @escaping () -> ModelAvailability,
        forceUnlocked: Bool = false,
        entitlement: ReflectionEntitlement? = nil,
        purchase: ReflectionPurchase? = nil
    ) {
        self.generator = generator
        self.availabilityProvider = availabilityProvider
        self.availability = availabilityProvider()
        self.forceUnlocked = forceUnlocked
        self.entitlement = entitlement
        self.purchase = purchase
    }

    /// Reads what is owned, then follows purchases and refunds for the rest of the session.
    func start() async {
        await entitlement?.start()
    }

    func refreshAvailability() {
        availability = availabilityProvider()
    }

    /// The real model on iOS 26 and later. Everything else is `unsupported`, so the surfaces hide.
    static func make() -> ReflectionCenter {
        #if DEBUG
        // Canned output, unlocked: layout checks and screenshots.
        if ProcessInfo.processInfo.arguments.contains("-ReflectionFake") {
            return ReflectionCenter(generator: FakeReflectionGenerator(), availabilityProvider: { .available }, forceUnlocked: true)
        }
        // The real model, unlocked, with no purchase.
        if ProcessInfo.processInfo.arguments.contains("-ReflectionUnlockOnly"), #available(iOS 26, *) {
            return ReflectionCenter(generator: LiveReflectionService(), availabilityProvider: LiveReflectionService.availability, forceUnlocked: true)
        }
        #endif
        if #available(iOS 26, *) {
            let entitlement = ReflectionEntitlement()
            return ReflectionCenter(
                generator: LiveReflectionService(),
                availabilityProvider: LiveReflectionService.availability,
                entitlement: entitlement,
                purchase: ReflectionPurchase(entitlement: entitlement)
            )
        }
        return ReflectionCenter(generator: UnavailableReflectionGenerator(), availabilityProvider: { .unsupported })
    }
}

/// Stands in below iOS 26. The gate hides every surface, so no call ever reaches it.
private struct UnavailableReflectionGenerator: ReflectionGenerating {
    func patterns(digest: PatternsDigest) async throws -> PatternsOutput { throw ReflectionError.failed }
    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput { throw ReflectionError.failed }
    func cleanUp(note: String) async throws -> CleanedNote { throw ReflectionError.failed }
}
