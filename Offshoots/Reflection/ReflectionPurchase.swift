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
    /// TestFlight evaluation builds only: the raw StoreKit result behind a buy or restore, for the screen.
    private(set) var diagnostic: String?
    @ObservationIgnored private var product: Product?
    @ObservationIgnored private let entitlement: ReflectionEntitlement

    @ObservationIgnored private let canPurchase: () -> Bool
    @ObservationIgnored private let featureName: String
    @ObservationIgnored private let purchaseBlockedMessage: String

    init(entitlement: ReflectionEntitlement, canPurchase: @escaping () -> Bool = { true },
         featureName: String = "Reflection",
         purchaseBlockedMessage: String = "Apple Intelligence must be available before you purchase Reflection. Check device and language support, then try again.") {
        self.featureName = featureName
        self.purchaseBlockedMessage = purchaseBlockedMessage
        self.canPurchase = canPurchase
        self.entitlement = entitlement
    }

    #if DEBUG
    /// Shows a ready price without StoreKit. Layout checks only; buying stays on the real product path.
    func useLayoutFixture(price: String) {
        state = .ready(displayPrice: price)
    }
    #endif

    func loadProduct() async {
        // A reopened sheet keeps a pending Ask to Buy, so it cannot start a second purchase.
        if state != .pending { state = .loading }
        restoreMessage = nil
        do {
            let products = try await Product.products(for: ReflectionEntitlement.acceptedProductIDs)
            if let first = products.first {
                product = first
                if state != .pending { state = .ready(displayPrice: first.displayPrice) }
            } else {
                state = .unavailable
            }
        } catch {
            if state != .pending { state = .unavailable }
        }
    }

    /// Returns true when the purchase went through and the unlock is on.
    @discardableResult
    func buy() async -> Bool {
        guard canPurchase() else {
            state = .failed(purchaseBlockedMessage)
            return false
        }
        guard state != .purchasing && state != .pending else { return false }
        guard let product else { return false }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await entitlement.refresh()
                // An earlier "No earlier purchase was found." is now wrong
                restoreMessage = nil
                #if HINDSIGHT_TESTFLIGHT
                if !entitlement.isUnlocked {
                    diagnostic = await "Buy: verified, finished, still locked.\n" + StoreKitEntitlementSource.describe()
                }
                #endif
                state = .ready(displayPrice: product.displayPrice)
                return entitlement.isUnlocked
            case .success(.unverified):
                #if HINDSIGHT_TESTFLIGHT
                diagnostic = "Buy: unverified result.\n" + (await StoreKitEntitlementSource.describe())
                #endif
                state = .failed("The purchase could not be verified. If you were charged, tap Restore Purchase later or contact Apple Support.")
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

    /// StoreKit reports a missing App Store sign-in as `StoreKitInternalError.noAccount`, a type the SDK does not export.
    nonisolated static func restoreFailureMessage(for error: Error) -> String {
        if String(reflecting: error).contains("noAccount") {
            return "Sign in to the App Store in Settings, then try again."
        }
        return "Restore did not finish. Try again."
    }

    func restore() async {
        restoreMessage = nil
        diagnostic = nil
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await entitlement.refresh()
            #if HINDSIGHT_TESTFLIGHT
            diagnostic = "Restore: sync ok.\n" + (await StoreKitEntitlementSource.describe())
            #endif
            if entitlement.latestVerificationFailed {
                restoreMessage = "The purchase could not be verified. Try Restore Purchase again later."
            } else if entitlement.isUnlocked {
                restoreMessage = "\(featureName) is unlocked."
            } else if entitlement.hasResolvedOwnership {
                restoreMessage = "No earlier purchase was found."
            } else {
                restoreMessage = "The purchase could not be verified. Try Restore Purchase again later."
            }
        } catch {
            #if HINDSIGHT_TESTFLIGHT
            diagnostic = "Restore: sync threw \(String(reflecting: error)).\n" + (await StoreKitEntitlementSource.describe())
            #endif
            restoreMessage = Self.restoreFailureMessage(for: error)
        }
    }
}
