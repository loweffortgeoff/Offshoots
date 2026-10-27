import Foundation
import Testing
@testable import Offshoots

@MainActor
struct HindsightSummaryTests {
    @Test func skippedRevisitKeepsOriginalPair() throws {
        var d = Make.marked(.good, .bad)
        d.hindsight = .differentApproach
        d.revisits = [Revisit(date: Make.day(12), outcome: .good)]
        let entries = HindsightSummary.entries(from: [d])
        let e = try #require(entries.first)
        #expect(entries.count == 1)
        #expect(e.answer == .differentApproach)
        #expect(e.outcome == .bad)
        #expect(e.date == Make.day(7))
        #expect(e.revisitID == nil)
        #expect(HindsightSummary.filtered(entries, answer: .differentApproach, outcome: .good).isEmpty)
    }

    @Test func countsExcludeSkippedAndKeepExplicitUncertainty() throws {
        var a = Make.marked(.good, .bad); a.hindsight = .differentApproach
        var b = Make.marked(); b.hindsight = .differentChoice
        b.revisits = [Revisit(date: Make.day(8), outcome: .bad, hindsight: .sameApproach)]
        var c = Make.marked(); c.hindsight = .notSure
        let d = Make.marked()
        let entries = HindsightSummary.entries(from: [a,b,c,d])
        #expect(entries.count == 3)
        #expect(HindsightSummary.count(.notSure, in: entries) == 1)
        #expect(HindsightSummary.count(.differentChoice, in: entries) == 0)
        #expect(HindsightSummary.filtered(entries, answer: .sameApproach, outcome: .bad).map(\.decisionID) == [b.id])
        #expect(HindsightSummary.filtered(entries, answer: .differentChoice, outcome: .bad).isEmpty)
        #expect(HindsightSummary.filtered(entries, answer: nil, outcome: nil).count == 3)
    }

    @Test func recordedOrderWinsForTiedAndBackdatedRevisits() throws {
        var d = Make.marked()
        let latest = Revisit(date: Make.day(2), outcome: .bad, note: "Recorded last", hindsight: .differentChoice)
        d.revisits = [Revisit(date: Make.day(20), outcome: .good, hindsight: .sameApproach),
                      Revisit(date: Make.day(20), outcome: .neutral, hindsight: .notSure), latest]
        let e = try #require(HindsightSummary.entries(from: [d]).first)
        #expect(e.revisitID == latest.id)
        #expect(e.date == Make.day(2))
        #expect(e.outcome == .bad)
        #expect(e.note == "Recorded last")
    }

    @Test func pendingAndEmptyDataHaveNoEntries() {
        var d = Make.decision(); d.hindsight = .sameApproach
        #expect(HindsightSummary.entries(from: [d]).isEmpty)
        #expect(HindsightSummary.entries(from: []).isEmpty)
    }

    @Test func notesRemainPairedAndCategoryTracksTheDecision() throws {
        var d = Make.marked(.good, .bad)
        d.category = .work
        d.hindsight = .differentApproach
        d.reflection = "First note"
        d.revisits = [Revisit(date: Make.day(12), outcome: .good, note: "Skipped note")]
        var entry = try #require(HindsightSummary.entries(from: [d]).first)
        #expect(entry.note == "First note")
        #expect(entry.outcome == .bad)
        #expect(entry.date == Make.day(7))
        #expect(entry.category == .work)

        d.revisits.append(Revisit(date: Make.day(2), outcome: .neutral, hindsight: .sameApproach))
        d.category = .home
        entry = try #require(HindsightSummary.entries(from: [d]).first)
        #expect(entry.note == nil)
        #expect(entry.answer == .sameApproach)
        #expect(entry.outcome == .neutral)
        #expect(entry.date == Make.day(2))
        #expect(entry.category == .home)
    }
}
