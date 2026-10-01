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
    /// Set by StoreKit in Task 5. Until then only the debug launch flag turns it on.
    var isUnlocked: Bool
    @ObservationIgnored let generator: any ReflectionGenerating
    @ObservationIgnored private let availabilityProvider: () -> ModelAvailability

    var gate: ReflectionSurfaceState {
        ReflectionGate.state(availability: availability, isUnlocked: isUnlocked)
    }

    init(
        generator: any ReflectionGenerating,
        availabilityProvider: @escaping () -> ModelAvailability,
        isUnlocked: Bool = false
    ) {
        self.generator = generator
        self.availabilityProvider = availabilityProvider
        self.availability = availabilityProvider()
        self.isUnlocked = isUnlocked
    }

    func refreshAvailability() {
        availability = availabilityProvider()
    }

    /// The real model on iOS 26 and later. Everything else is `unsupported`, so the surfaces hide.
    static func make() -> ReflectionCenter {
        #if DEBUG
        // Simulator and screenshot runs: no model, so fake it and unlock it.
        if ProcessInfo.processInfo.arguments.contains("-ReflectionFake") {
            return ReflectionCenter(generator: FakeReflectionGenerator(), availabilityProvider: { .available }, isUnlocked: true)
        }
        // Device runs before StoreKit lands: the real model, unlocked.
        if ProcessInfo.processInfo.arguments.contains("-ReflectionUnlockOnly"), #available(iOS 26, *) {
            return ReflectionCenter(generator: LiveReflectionService(), availabilityProvider: LiveReflectionService.availability, isUnlocked: true)
        }
        #endif
        if #available(iOS 26, *) {
            return ReflectionCenter(generator: LiveReflectionService(), availabilityProvider: LiveReflectionService.availability)
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
