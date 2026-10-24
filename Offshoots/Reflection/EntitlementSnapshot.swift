import Foundation

struct EntitlementSnapshot: Equatable {
    let verifiedProductIDs: Set<String>
    let revokedProductIDs: Set<String>
    let hasVerificationFailure: Bool

    init(verifiedProductIDs: Set<String>, revokedProductIDs: Set<String> = [], hasVerificationFailure: Bool) {
        self.verifiedProductIDs = verifiedProductIDs
        self.revokedProductIDs = revokedProductIDs
        self.hasVerificationFailure = hasVerificationFailure
    }
}
