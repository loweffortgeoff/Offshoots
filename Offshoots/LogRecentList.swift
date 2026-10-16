//
//  LogRecentList.swift
//  Offshoots
//

/// What the Log screen lists beside the form on a wide Duo: recent decisions in the
/// category being logged, or recent decisions in any category when that one has none.
enum LogRecentList: Equatable {
    case category(DecisionCategory, [Decision])
    case all([Decision])
    case none

    static let limit = 10

    /// `all` is newest first, as the store keeps it, and the list keeps that order.
    static func make(category: DecisionCategory, from all: [Decision]) -> LogRecentList {
        let inCategory = all.filter { $0.category == category }
        if !inCategory.isEmpty {
            return .category(category, Array(inCategory.prefix(limit)))
        }
        if !all.isEmpty {
            return .all(Array(all.prefix(limit)))
        }
        return .none
    }
}
