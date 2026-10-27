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
    /// Paid Reflection is reserved for 2.1.0 after its physical-device quality gate.
    private static let paidFeaturesEnabled = false

    private(set) var availability: ModelAvailability
    /// Debug launch flags only. A real unlock comes from `entitlement`.
    @ObservationIgnored private let forceUnlocked: Bool
    @ObservationIgnored let entitlement: ReflectionEntitlement?
    /// Nil while the paid release is disabled, and in explicit developer branches.
    @ObservationIgnored let purchase: ReflectionPurchase?
    @ObservationIgnored let generator: any ReflectionGenerating
    @ObservationIgnored private let availabilityProvider: () -> ModelAvailability

    /// Reads the observable entitlement, so a purchase or a refund updates every surface
    var isUnlocked: Bool {
        forceUnlocked || entitlement?.isUnlocked == true
    }

    var canGenerate: Bool { gate == .enabled }
    var canReadHistory: Bool { true }

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
        self.generator = ReflectionProviderCoordinator(base: generator)
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

    /// DEBUG launch arguments come first for local evaluation; the release switch then runs before availability and StoreKit.
    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> ReflectionCenter {
        #if DEBUG
        // Locked layout preview. Buying is disabled in this explicit developer configuration.
        if arguments.contains("-ReflectionFakeLocked") {
            let entitlement = ReflectionEntitlement()
            return ReflectionCenter(generator: FakeReflectionGenerator(), availabilityProvider: { .available },
                entitlement: entitlement, purchase: ReflectionPurchase(entitlement: entitlement, canPurchase: { false }))
        }
        // Canned output, unlocked: layout checks and screenshots.
        if arguments.contains("-ReflectionFake") {
            return ReflectionCenter(generator: FakeReflectionGenerator(), availabilityProvider: { .available }, forceUnlocked: true)
        }
        // The real model, unlocked, with no purchase.
        if arguments.contains("-ReflectionUnlockOnly"), #available(iOS 26, *) {
            return ReflectionCenter(generator: LiveReflectionService(), availabilityProvider: LiveReflectionService.availability, forceUnlocked: true)
        }
        #endif
        guard paidFeaturesEnabled else {
            return ReflectionCenter(generator: UnavailableReflectionGenerator(), availabilityProvider: { .unsupported })
        }
        if #available(iOS 26, *) {
            return makePaid(generator: LiveReflectionService(), availabilityProvider: LiveReflectionService.availability)
        }
        return makePaid(generator: UnavailableReflectionGenerator(), availabilityProvider: { .unsupported })
    }

    /// Ownership and Restore do not depend on model or OS eligibility for generation.
    static func makePaid(generator: any ReflectionGenerating, availabilityProvider: @escaping () -> ModelAvailability) -> ReflectionCenter {
        let entitlement = ReflectionEntitlement()
        return ReflectionCenter(generator: generator, availabilityProvider: availabilityProvider,
            entitlement: entitlement,
            purchase: ReflectionPurchase(entitlement: entitlement, canPurchase: { availabilityProvider() == .available }))
    }

}

/// Stands in while paid Reflection is deferred, or below iOS 26. No model or StoreKit work.
private struct UnavailableReflectionGenerator: ReflectionGenerating {
    func patterns(digest: PatternsDigest) async throws -> PatternsOutput { throw ReflectionError.failed }
    func reflect(on digest: DecisionDigest) async throws -> DecisionReflectionOutput { throw ReflectionError.failed }
    func lookBack(digest: LookBackDigest) async throws -> LookBackOutput { throw ReflectionError.failed }
    func cleanUp(note: String) async throws -> CleanedNote { throw ReflectionError.failed }
}
