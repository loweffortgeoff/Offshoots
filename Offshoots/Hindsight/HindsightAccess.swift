import Foundation
import Observation

@MainActor @Observable
final class HindsightAccess {
    private static let productionEnabled = false
    let isEnabled: Bool
    let entitlement: ReflectionEntitlement?
    let purchase: ReflectionPurchase?
    var canCapture: Bool { isEnabled && entitlement?.isUnlocked == true }

    init(isEnabled: Bool, entitlement: ReflectionEntitlement?, purchase: ReflectionPurchase?) {
        self.isEnabled = isEnabled
        self.entitlement = entitlement
        self.purchase = purchase
    }

    func start() async { await entitlement?.start() }
    func refresh() async { await entitlement?.refresh() }
    func showsInsights(hasSavedAnswers: Bool) -> Bool { isEnabled || hasSavedAnswers }

    /// Authorize and mutate synchronously. A rejected optional answer never becomes a free partial save.
    @discardableResult
    func performSave(answer: HindsightAnswer?, save: (HindsightAnswer?) -> Void) -> Bool {
        guard answer == nil || canCapture else { return false }
        save(answer)
        return true
    }

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> HindsightAccess {
        #if DEBUG
        if arguments.contains("-HindsightPreview") || arguments.contains("-HindsightLocked") {
            let owned = arguments.contains("-HindsightPreview")
            let entitlement = ReflectionEntitlement(source: HindsightPreviewEntitlementSource(owned: owned))
            return HindsightAccess(isEnabled: true, entitlement: entitlement,
                purchase: ReflectionPurchase(entitlement: entitlement, canPurchase: { false },
                    featureName: "Hindsight", purchaseBlockedMessage: "Purchases are disabled in this preview."))
        }
        if arguments.contains("-HindsightStoreKit") { return enabled() }
        #endif
        guard productionEnabled else { return HindsightAccess(isEnabled: false, entitlement: nil, purchase: nil) }
        return enabled()
    }

    private static func enabled() -> HindsightAccess {
        let entitlement = ReflectionEntitlement()
        return HindsightAccess(isEnabled: true, entitlement: entitlement,
            purchase: ReflectionPurchase(entitlement: entitlement, canPurchase: { true },
                featureName: "Hindsight", purchaseBlockedMessage: "Hindsight is not available for purchase yet."))
    }
}
