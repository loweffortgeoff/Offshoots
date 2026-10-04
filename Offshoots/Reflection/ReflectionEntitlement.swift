//
//  ReflectionEntitlement.swift
//  Offshoots
//

import Foundation
import Observation
import StoreKit

/// Where the owned product IDs come from. StoreKit in the app, a hand-driven fake in tests.
protocol ReflectionEntitlementSource {
    func currentProductIDs() async -> Set<String>
    /// The full set of owned IDs, sent again after every change (purchase, refund, restore)
    func updates() -> AsyncStream<Set<String>>
}

/// Whether Reflection is unlocked. It checks a list of product IDs, so a one-time purchase
/// and a later subscription can both unlock without any other change.
@Observable
final class ReflectionEntitlement {
    /// Add a subscription's ID here if one ever ships. Never remove the one-time ID.
    static let acceptedProductIDs: Set<String> = ["com.geoffrey.silva.Offshoots.reflection"]

    private(set) var isUnlocked = false
    @ObservationIgnored private let source: any ReflectionEntitlementSource
    @ObservationIgnored private let accepted: Set<String>
    @ObservationIgnored private var listener: Task<Void, Never>?

    init(source: any ReflectionEntitlementSource = StoreKitEntitlementSource(), accepted: Set<String> = acceptedProductIDs) {
        self.source = source
        self.accepted = accepted
    }

    static func unlocks(entitled: Set<String>, accepted: Set<String>) -> Bool {
        !entitled.isDisjoint(with: accepted)
    }

    /// Reads what is owned now, then keeps listening for changes.
    func start() async {
        await refresh()
        listener?.cancel()
        listener = listen()
    }

    func refresh() async {
        isUnlocked = Self.unlocks(entitled: await source.currentProductIDs(), accepted: accepted)
    }

    @discardableResult
    func listen() -> Task<Void, Never> {
        // Subscribe before the task starts, so a change sent right away is not missed
        let updates = source.updates()
        let accepted = accepted
        return Task { [weak self] in
            for await ids in updates {
                self?.isUnlocked = Self.unlocks(entitled: ids, accepted: accepted)
            }
        }
    }
}

/// The StoreKit 2 source. Revoked (refunded) transactions do not count.
struct StoreKitEntitlementSource: ReflectionEntitlementSource {
    func currentProductIDs() async -> Set<String> {
        var ids = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                ids.insert(transaction.productID)
            }
        }
        return ids
    }

    func updates() -> AsyncStream<Set<String>> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    if case .verified(let transaction) = result {
                        await transaction.finish()
                    }
                    continuation.yield(await currentProductIDs())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
