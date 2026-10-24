#if DEBUG
import Foundation

/// Explicit layout fixture, never a source of production ownership.
struct HindsightPreviewEntitlementSource: ReflectionEntitlementSource {
    let owned: Bool
    func currentSnapshot() async -> EntitlementSnapshot {
        .init(verifiedProductIDs: owned ? ReflectionEntitlement.acceptedProductIDs : [], hasVerificationFailure: false)
    }
    func updates() -> AsyncStream<EntitlementSnapshot> { AsyncStream { $0.finish() } }
}
#endif
