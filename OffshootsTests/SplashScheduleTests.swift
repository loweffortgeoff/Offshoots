//
//  SplashScheduleTests.swift
//  OffshootsTests
//
//  Created by Geoffrey Silva on 10/9/26.
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct SplashScheduleTests {

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    static func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    @Test func showsWhenNeverShown() {
        #expect(SplashSchedule.isDue(lastShown: 0, now: Self.date("2026-10-09T13:00:00Z"), calendar: Self.calendar))
    }

    @Test func skipsLaterTheSameDay() {
        let morning = Self.date("2026-10-09T12:00:00Z").timeIntervalSinceReferenceDate  // 08:00 New York
        let evening = Self.date("2026-10-10T02:00:00Z")                                // 22:00 New York, same day
        #expect(!SplashSchedule.isDue(lastShown: morning, now: evening, calendar: Self.calendar))
    }

    @Test func showsAgainAfterMidnight() {
        let lateNight = Self.date("2026-10-10T03:30:00Z").timeIntervalSinceReferenceDate  // 23:30 New York
        let nextMorning = Self.date("2026-10-10T04:30:00Z")                              // 00:30 New York, next day
        #expect(SplashSchedule.isDue(lastShown: lateNight, now: nextMorning, calendar: Self.calendar))
    }

    @Test func farFutureHidesIt() {
        #expect(!SplashSchedule.isDue(lastShown: 9_999_999_999, now: Self.date("2026-10-09T13:00:00Z"), calendar: Self.calendar))
    }
}
