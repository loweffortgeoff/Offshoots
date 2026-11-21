//
//  WidgetSummaryTests.swift
//  OffshootsTests
//

import Foundation
import Testing
@testable import Offshoots

@MainActor
@Suite struct WidgetSummaryTests {
    /// "Now" is 2026-09-27 12:00 UTC, as in AnalyticsEngineTests
    let now = Make.day(26)
    let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func pending(_ title: String, due: Date) -> Decision {
        Decision(title: title, category: .work, expected: .good, createdAt: Make.day(0), followUpDate: due)
    }

    @Test func reviewLaterTodayIsDue() {
        #expect(DueDay.isDue(now.addingTimeInterval(3600), asOf: now, calendar: utc))
        #expect(!DueDay.isDue(Make.day(27), asOf: now, calendar: utc))
    }

    @Test func keepsAllDueAndTenUpcoming() {
        let due = (0..<25).map { pending("Due \($0)", due: Make.day(1 + $0 % 20)) }
        let upcoming = (0..<15).map { pending("Later \($0)", due: Make.day(28 + $0)) }
        let summary = WidgetSummary(decisions: due + upcoming, hindsightOwned: false, now: now, calendar: utc)
        #expect(summary.due(asOf: now, calendar: utc).count == 25)
        #expect(summary.upcoming(asOf: now, calendar: utc).count == 10)
        #expect(summary.items.map(\.dueDate) == summary.items.map(\.dueDate).sorted())
    }

    @Test func resolvedWithoutRevisitDateIsLeftOut() {
        let resolved = Decision(title: "Done", category: .work, expected: .good, actual: .good,
                                createdAt: Make.day(0), resolvedAt: Make.day(7), followUpDate: Make.day(7))
        let revisit = Decision(title: "Revisit", category: .work, expected: .good, actual: .good,
                               createdAt: Make.day(0), resolvedAt: Make.day(7), followUpDate: Make.day(7),
                               secondaryFollowUpDate: Make.day(20))
        let summary = WidgetSummary(decisions: [resolved, revisit], hindsightOwned: false, now: now, calendar: utc)
        #expect(summary.items.map(\.title) == ["Revisit"])
        #expect(summary.items.first?.dueDate == Make.day(20))
    }

    @Test func fixtureBuildsWithoutNotes() throws {
        let decisions = try Fixture.load("screenshots")
        let data = try WidgetSummary(decisions: decisions, hindsightOwned: true, now: now).encoded()
        let json = String(decoding: data, as: UTF8.self)
        for d in decisions {
            if let n = d.notes, !n.isEmpty { #expect(!json.contains(n)) }
            if let r = d.reflection, !r.isEmpty { #expect(!json.contains(r)) }
        }
        #expect(WidgetSummary.decode(data)?.hindsightOwned == true)
    }

    @Test func badFilesDecodeToNil() {
        #expect(WidgetSummary.decode(Data("garbage".utf8)) == nil)
        #expect(WidgetSummary.decode(Data(#"{"version":2,"hindsightOwned":false,"items":[]}"#.utf8)) == nil)
    }

    @Test func refreshDatesAreStartsOfLaterDueDays() {
        let summary = WidgetSummary(decisions: [
            pending("Overdue", due: Make.day(20)),
            pending("Soon", due: Make.day(28).addingTimeInterval(3 * 3600)),
            pending("Same day", due: Make.day(28)),
            pending("Later", due: Make.day(30)),
        ], hindsightOwned: false, now: now, calendar: utc)
        let dates = summary.refreshDates(after: now, calendar: utc)
        #expect(dates == [utc.startOfDay(for: Make.day(28)), utc.startOfDay(for: Make.day(30))])
        #expect(summary.refreshDates(after: now, limit: 1, calendar: utc).count == 1)
    }
}
