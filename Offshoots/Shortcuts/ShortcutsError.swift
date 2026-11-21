//
//  ShortcutsError.swift
//  Offshoots
//

import Foundation

/// Errors that Siri and the Shortcuts app show as written. Only an error that
/// provides a `LocalizedStringResource` surfaces its own message.
enum ShortcutsError: Error, Equatable, Hashable, CustomLocalizedStringResourceConvertible {
    /// A restore needs recovery, so nothing may write to the journal
    case blocked
    case blankTitle
    /// A new decision's review date is earlier than tomorrow
    case reviewDateTooEarly
    case revisitDateInPast
    /// The decision was deleted after the shortcut picked it
    case decisionMissing

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .blocked: "Offshoots needs attention before it can save. Open the app to finish the restore."
        case .blankTitle: "What decision are you making?"
        case .reviewDateTooEarly: "Pick a review date of tomorrow or later."
        case .revisitDateInPast: "Pick a revisit date of today or later."
        case .decisionMissing: "That decision is no longer in Offshoots."
        }
    }
}
