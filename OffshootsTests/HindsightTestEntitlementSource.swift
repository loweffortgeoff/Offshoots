import Foundation
@testable import Offshoots

@MainActor
final class HindsightTestEntitlementSource: ReflectionEntitlementSource {
    var snapshot: EntitlementSnapshot
    var delayNextRead = false
    var onRead: (() -> Void)?
    private(set) var pendingRead: CheckedContinuation<Void, Never>?
    private var continuation: AsyncStream<EntitlementSnapshot>.Continuation?
    init(snapshot: EntitlementSnapshot = .init(verifiedProductIDs: [], hasVerificationFailure: false)) {
        self.snapshot = snapshot
    }
    func currentSnapshot() async -> EntitlementSnapshot {
        let captured = snapshot
        onRead?()
        if delayNextRead {
            delayNextRead = false
            await withCheckedContinuation { pendingRead = $0 }
        }
        return captured
    }
    func updates() -> AsyncStream<EntitlementSnapshot> {
        AsyncStream { continuation = $0 }
    }
    func push(_ value: EntitlementSnapshot) { snapshot = value; continuation?.yield(value) }
    func finish() { continuation?.finish() }
    func resumeRead() { pendingRead?.resume(); pendingRead = nil }
}
