//
//  ReflectionPurchase.swift
//  Offshoots
//

import Foundation
import Observation
import StoreKit

/// Loads the product, buys it and restores it. The price shown is always `displayPrice` from StoreKit.
@Observable
final class ReflectionPurchase {
    enum State: Equatable {
        case loading
        case ready(displayPrice: String)
        case unavailable
        case purchasing
        case pending
        case failed(String)
    }

    private(set) var state: State = .loading
    /// Set after a restore: what happened, in words
    private(set) var restoreMessage: String?
    private(set) var isRestoring = false
    @ObservationIgnored private var product: Product?
    @ObservationIgnored private let entitlement: ReflectionEntitlement

    init(entitlement: ReflectionEntitlement) {
        self.entitlement = entitlement
    }

    func loadProduct() async {
        state = .loading
        do {
            let products = try await Product.products(for: ReflectionEntitlement.acceptedProductIDs)
            if let first = products.first {
                product = first
                state = .ready(displayPrice: first.displayPrice)
            } else {
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
    }

    /// Returns true when the purchase went through and the unlock is on.
    @discardableResult
    func buy() async -> Bool {
        guard let product else { return false }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await entitlement.refresh()
                // An earlier "No earlier purchase was found." is now wrong
                restoreMessage = nil
                state = .ready(displayPrice: product.displayPrice)
                return entitlement.isUnlocked
            case .success(.unverified):
                state = .failed("The purchase could not be verified. You were not charged.")
            case .pending:
                state = .pending
            case .userCancelled:
                state = .ready(displayPrice: product.displayPrice)
            @unknown default:
                state = .ready(displayPrice: product.displayPrice)
            }
        } catch {
            print("[ReflectionPurchase] ❌ Purchase failed:", error)
            state = .failed("The purchase did not go through. Try again.")
        }
        return false
    }

    func restore() async {
        restoreMessage = nil
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await entitlement.refresh()
            restoreMessage = entitlement.isUnlocked ? "Reflection is unlocked." : "No earlier purchase was found."
        } catch {
            restoreMessage = "Restore did not finish. Try again."
        }
    }
}
