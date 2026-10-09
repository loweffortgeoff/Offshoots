//
//  ReviewDatePreset.swift
//  Offshoots
//

import Foundation

/// Quick review-date choices on Log and Edit. Each adds whole days to now and
/// keeps the time of day, so reminder timing stays as it was
enum ReviewDatePreset: Int, CaseIterable, Identifiable {
    case tomorrow = 1
    case threeDays = 3
    case oneWeek = 7
    case oneMonth = 30

    var id: Int { rawValue }

    var days: Int { rawValue }

    var label: String {
        switch self {
        case .tomorrow: return "Tomorrow"
        case .threeDays: return "3 days"
        case .oneWeek: return "1 week"
        case .oneMonth: return "1 month"
        }
    }

    func date(from now: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: now)!
    }

    /// The preset that falls on the same day as `date`, counted from `now`
    static func matching(_ date: Date, from now: Date = Date(), calendar: Calendar = .current) -> ReviewDatePreset? {
        allCases.first { calendar.isDate($0.date(from: now, calendar: calendar), inSameDayAs: date) }
    }

    /// A review date that is no longer in the future moves back to tomorrow. A
    /// date that is still tomorrow or later stays, so a pick the user made is kept
    static func refreshed(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Date {
        let startOfTomorrow = calendar.startOfDay(for: tomorrow.date(from: now, calendar: calendar))
        return date < startOfTomorrow ? tomorrow.date(from: now, calendar: calendar) : date
    }
}
