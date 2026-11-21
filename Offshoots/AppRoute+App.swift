//
//  AppRoute+App.swift
//  Offshoots
//

import Foundation

/// The Decisions navigation path for a routed decision. A decision deleted since the link was made opens the list root.
enum DecisionRoute {
    static func path(for id: UUID, in decisions: [Decision]) -> [Decision] {
        decisions.first { $0.id == id }.map { [$0] } ?? []
    }
}

/// Where a Hindsight link lands. It waits for StoreKit, so an owner never sees the purchase sheet on a cold launch.
nonisolated enum HindsightRouteTarget: Equatable {
    case wait, review, insights, purchase

    static func resolve(hasResolvedOwnership: Bool, canCapture: Bool, entryCount: Int) -> HindsightRouteTarget {
        guard hasResolvedOwnership else { return .wait }
        guard canCapture else { return .purchase }
        return entryCount > 0 ? .review : .insights
    }
}
