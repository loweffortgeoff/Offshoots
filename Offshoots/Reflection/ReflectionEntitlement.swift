import Foundation
import Observation
import StoreKit

protocol ReflectionEntitlementSource {
    func currentSnapshot() async -> EntitlementSnapshot
    func updates() -> AsyncStream<EntitlementSnapshot>
}

/// Shared one-time ownership. Model and product-loading availability are separate.
@Observable
final class ReflectionEntitlement {
    static let acceptedProductIDs: Set<String> = ["com.geoffrey.silva.Offshoots.reflection"]
    private(set) var isUnlocked = false
    private(set) var hasResolvedOwnership = false
    private(set) var latestVerificationFailed = false
    @ObservationIgnored private let source: any ReflectionEntitlementSource
    @ObservationIgnored private let accepted: Set<String>
    @ObservationIgnored private var listener: Task<Void, Never>?
    @ObservationIgnored private var revision = 0

    init(source: any ReflectionEntitlementSource = StoreKitEntitlementSource(), accepted: Set<String> = acceptedProductIDs) {
        self.source = source
        self.accepted = accepted
    }

    static func unlocks(entitled: Set<String>, accepted: Set<String>) -> Bool {
        !entitled.isDisjoint(with: accepted)
    }

    /// Safe to call from every owner of a shared entitlement: one listener per instance.
    func start() async {
        if listener == nil { listener = listen() }
        await refresh()
    }

    func refresh() async {
        revision += 1
        let request = revision
        let snapshot = await source.currentSnapshot()
        guard revision == request else { return }
        apply(snapshot)
    }

    @discardableResult
    func listen() -> Task<Void, Never> {
        let updates = source.updates()
        return Task { [weak self] in
            for await snapshot in updates {
                guard !Task.isCancelled else { break }
                self?.revision += 1
                self?.apply(snapshot)
            }
        }
    }

    private func apply(_ snapshot: EntitlementSnapshot) {
        latestVerificationFailed = snapshot.hasVerificationFailure
        let owned = snapshot.verifiedProductIDs.subtracting(snapshot.revokedProductIDs)
        if Self.unlocks(entitled: owned, accepted: accepted) {
            isUnlocked = true
            hasResolvedOwnership = true
        } else if !snapshot.revokedProductIDs.isDisjoint(with: accepted) || !snapshot.hasVerificationFailure {
            isUnlocked = false
            hasResolvedOwnership = true
        }
        // Uncertainty cannot grant new access or erase ownership verified earlier in this process.
        // Cold-launch ownership comes from StoreKit's locally verified transaction cache.
    }
}

struct StoreKitEntitlementSource: ReflectionEntitlementSource {
    func currentSnapshot() async -> EntitlementSnapshot {
        var ids = Set<String>()
        var failedVerification = false
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.revocationDate == nil { ids.insert(transaction.productID) }
            case .unverified:
                failedVerification = true
            }
        }
        return EntitlementSnapshot(verifiedProductIDs: ids, hasVerificationFailure: failedVerification)
    }

    #if HINDSIGHT_TESTFLIGHT
    /// One line per transaction StoreKit knows about, so a locked screen after a purchase can be explained.
    static func describe() async -> String {
        func line(_ result: VerificationResult<Transaction>, tag: String) -> String {
            switch result {
            case .verified(let t):
                return "\(tag) verified \(t.productID) env=\(t.environment.rawValue) revoked=\(t.revocationDate != nil)"
            case .unverified(let t, let error):
                return "\(tag) UNVERIFIED \(t.productID) env=\(t.environment.rawValue) \(String(reflecting: error))"
            }
        }
        var lines = [String]()
        for await result in Transaction.currentEntitlements { lines.append(line(result, tag: "entitled")) }
        if lines.isEmpty { lines.append("entitled: none") }
        var all = [String]()
        for await result in Transaction.all { all.append(line(result, tag: "all")) }
        return (lines + (all.isEmpty ? ["all: none"] : all)).joined(separator: "\n")
    }
    #endif

    func updates() -> AsyncStream<EntitlementSnapshot> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    let current = await currentSnapshot()
                    var ids = current.verifiedProductIDs
                    var revoked = Set<String>()
                    var failed = current.hasVerificationFailure
                    switch result {
                    case .verified(let transaction):
                        if transaction.revocationDate != nil {
                            ids.remove(transaction.productID)
                            revoked.insert(transaction.productID)
                        } else { ids.insert(transaction.productID) }
                        await transaction.finish()
                    case .unverified:
                        failed = true
                    }
                    continuation.yield(EntitlementSnapshot(verifiedProductIDs: ids,
                        revokedProductIDs: revoked, hasVerificationFailure: failed))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
