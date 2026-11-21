//
//  LockScreenPresentation.swift
//  Shared by the app and the widget extension
//

import Foundation

nonisolated struct LockScreenInlineLabel: Equatable {
    var text: String
    var systemImage: String
}

/// Pure formatting and tap-routing rules for the Lock Screen accessory widgets.
/// Kept in `Shared/` (Foundation-only) so `OffshootsTests` can cover every branch directly.
nonisolated enum LockScreenPresentation {
    private static let weekInSeconds: TimeInterval = 7 * 86_400

    static func rectangularRoute(due: [WidgetSummary.Item]) -> AppRoute {
        if due.count == 1, let only = due.first {
            return .decision(only.id)
        }
        return .readyToReview
    }

    static func inlineLabel(dueCount: Int, nextDueDate: Date?, now: Date) -> LockScreenInlineLabel {
        if dueCount > 0 {
            return LockScreenInlineLabel(text: "\(dueCount) ready to review", systemImage: "bell.badge.fill")
        }
        if let nextDueDate {
            let soon = nextDueDate.timeIntervalSince(now) < weekInSeconds
            let day = soon
                ? nextDueDate.formatted(.dateTime.weekday(.abbreviated))
                : nextDueDate.formatted(.dateTime.month(.abbreviated).day())
            return LockScreenInlineLabel(text: "Next review \(day)", systemImage: "bell")
        }
        return LockScreenInlineLabel(text: "Nothing to review", systemImage: "checkmark")
    }

    static func rectangularEmptySubtitle(nextDueDate: Date?, now: Date) -> String {
        guard let nextDueDate else { return "Log a decision" }
        let soon = nextDueDate.timeIntervalSince(now) < weekInSeconds
        let day = soon
            ? nextDueDate.formatted(.dateTime.weekday(.wide))
            : nextDueDate.formatted(.dateTime.month().day())
        return "Next: \(day)"
    }
}
