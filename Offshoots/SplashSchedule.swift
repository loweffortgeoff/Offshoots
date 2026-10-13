//
//  SplashSchedule.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 10/9/26.
//

import Foundation

/// The splash shows on the first cold launch of each day. Later launches that day,
/// and returns from the background, skip it.
enum SplashSchedule {
    /// UserDefaults key: when the splash last showed, as seconds since the reference date.
    /// 0 (never) shows the splash. A date in the far future hides it (screenshots).
    static let storageKey = "lastSplashDate"

    static func isDue(lastShown: TimeInterval, now: Date = .now, calendar: Calendar = .current) -> Bool {
        lastShown < calendar.startOfDay(for: now).timeIntervalSinceReferenceDate
    }
}
