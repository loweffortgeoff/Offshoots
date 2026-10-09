//
//  ReviewDatePresetTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReviewDatePresetTests {

    /// A fixed UTC calendar, so the tests do not depend on the machine's time zone
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static let now = ISO8601DateFormatter().date(from: "2026-09-27T15:42:00Z")!

    @Test func eachPresetAddsItsDaysAndKeepsTheTime() {
        for preset in ReviewDatePreset.allCases {
            let date = preset.date(from: Self.now, calendar: Self.calendar)
            #expect(Self.calendar.dateComponents([.day], from: Self.now, to: date).day == preset.days)
            #expect(Self.calendar.component(.hour, from: date) == 15)
            #expect(Self.calendar.component(.minute, from: date) == 42)
        }
    }

    @Test func presetDays() {
        #expect(ReviewDatePreset.allCases.map(\.days) == [1, 3, 7, 30])
    }

    @Test func matchingFindsThePresetOnTheSameDay() {
        // A calendar pick keeps its own time; only the day has to match
        let pickedOneWeekOut = Self.calendar.date(byAdding: .day, value: 7, to: Self.now)!
            .addingTimeInterval(-3 * 3600)
        #expect(ReviewDatePreset.matching(pickedOneWeekOut, from: Self.now, calendar: Self.calendar) == .oneWeek)
    }

    @Test func matchingIsNilForOtherDays() {
        let twoDaysOut = Self.calendar.date(byAdding: .day, value: 2, to: Self.now)!
        #expect(ReviewDatePreset.matching(twoDaysOut, from: Self.now, calendar: Self.calendar) == nil)
    }

    @Test func refreshedMovesAStaleDateToTomorrow() {
        // Set as "tomorrow" on the 27th; the clock now reads the 28th
        let stale = ReviewDatePreset.tomorrow.date(from: Self.now, calendar: Self.calendar)
        let nextDay = Self.calendar.date(byAdding: .day, value: 1, to: Self.now)!.addingTimeInterval(-15 * 3600)
        let refreshed = ReviewDatePreset.refreshed(stale, now: nextDay, calendar: Self.calendar)
        #expect(Self.calendar.isDate(refreshed, inSameDayAs: Self.calendar.date(byAdding: .day, value: 1, to: nextDay)!))
    }

    @Test func refreshedKeepsAFutureDate() {
        let weekOut = ReviewDatePreset.oneWeek.date(from: Self.now, calendar: Self.calendar)
        #expect(ReviewDatePreset.refreshed(weekOut, now: Self.now, calendar: Self.calendar) == weekOut)
        let tomorrow = ReviewDatePreset.tomorrow.date(from: Self.now, calendar: Self.calendar)
        #expect(ReviewDatePreset.refreshed(tomorrow, now: Self.now, calendar: Self.calendar) == tomorrow)
    }
}
