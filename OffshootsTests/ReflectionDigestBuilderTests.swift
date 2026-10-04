import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionDigestBuilderTests {

    // MARK: - Patterns

    @Test func patternsDigestReusesTheAnalyticsNumbers() throws {
        let decisions = try Fixture.load("insights-seed")
        let digest = ReflectionDigestBuilder.patterns(from: decisions, now: AnalyticsEngineTests.now)

        #expect(digest.resolvedCount == 6)
        #expect(digest.goodPercent == 50)
        #expect(digest.accuracy == AccuracyBreakdown(correct: 4, close: 1, incorrect: 1))
        #expect(digest.optimism?.lean == .optimistic)
        #expect(digest.trend == TrendResult(trend: .improving, isSoFar: false))
        #expect(digest.revisitedCount == 1)
        #expect(digest.revisitsChangingOutcome == 1)
    }

    @Test func patternsDigestGroupsByCategoryAndStakes() throws {
        let decisions = try Fixture.load("insights-seed")
        let digest = ReflectionDigestBuilder.patterns(from: decisions, now: AnalyticsEngineTests.now)

        // Equal counts sort by label; the pending Home decision is left out
        #expect(digest.categories == [
            GroupLine(label: "Money", resolved: 3, exact: 1),
            GroupLine(label: "Work", resolved: 3, exact: 3),
        ])
        #expect(digest.stakes == [GroupLine(label: "Medium", resolved: 6, exact: 4)])
    }

    @Test func patternsNotesAreCappedNewestFirstAndCleaned() {
        var decisions: [Decision] = []
        for index in 0..<10 {
            decisions.append(Make.decision(
                actual: .good,
                notes: "Note \(index)",
                createdAt: Make.day(index),
                resolvedAt: Make.day(index + 1)
            ))
        }
        decisions.append(Make.decision(actual: .good, notes: "   \n", createdAt: Make.day(20), resolvedAt: Make.day(21)))

        let digest = ReflectionDigestBuilder.patterns(from: decisions, now: Make.day(30))
        #expect(digest.notes.count == ReflectionDigestBuilder.maximumNotes)
        #expect(digest.notes.first == "Note 9")
        #expect(digest.notes.allSatisfy { !$0.isEmpty })
    }

    @Test func aHugeNoteIsCutInTheDigest() throws {
        let decisions = [Make.decision(actual: .good, notes: String(repeating: "word ", count: 5_000), resolvedAt: Make.day(2))]
        let digest = ReflectionDigestBuilder.patterns(from: decisions, now: Make.day(30))
        let note = try #require(digest.notes.first)
        #expect(note.count == ReflectionDigestBuilder.noteLimit)
    }

    // MARK: - Decision

    @Test func pendingDecisionHasNoDigest() {
        #expect(ReflectionDigestBuilder.decision(Make.decision()) == nil)
    }

    @Test func decisionDigestCountsDaysAndBuildsTheTimeline() throws {
        let revisit = Revisit(date: Make.day(40), outcome: .good, note: "  Turned out fine \n")
        let decision = Make.decision(
            title: "Move cities",
            category: .home,
            stakes: .high,
            expected: .good,
            actual: .bad,
            notes: "Rent was cheaper",
            reflection: "Hated the commute",
            createdAt: Make.day(0),
            resolvedAt: Make.day(10),
            revisits: [revisit]
        )
        let digest = try #require(ReflectionDigestBuilder.decision(decision))

        #expect(digest.title == "Move cities")
        #expect(digest.category == "Home")
        #expect(digest.stakes == "High")
        #expect(digest.expected == "Good")
        #expect(digest.firstOutcome == "Bad")
        #expect(digest.daysToFirstOutcome == 10)
        #expect(digest.timeline == [TimelineLine(daysAfterFirstOutcome: 30, outcome: "Good", note: "Turned out fine")])
        #expect(digest.notes == "Rent was cheaper")
        #expect(digest.outcomeNote == "Hated the commute")
    }

    @Test func legacyDecisionWithoutResolvedAtFallsBackToItsReviewDate() throws {
        // `Make.decision` sets the review date to day 7
        let digest = try #require(ReflectionDigestBuilder.decision(Make.decision(actual: .good, notes: "x", resolvedAt: nil)))
        #expect(digest.daysToFirstOutcome == 7)
    }

    @Test func daysNeverGoNegative() throws {
        // A first outcome dated before creation (clock changes, imports) must not read "-3 days"
        let decision = Make.decision(actual: .good, notes: "x", createdAt: Make.day(10), resolvedAt: Make.day(7))
        let digest = try #require(ReflectionDigestBuilder.decision(decision))
        #expect(digest.daysToFirstOutcome == 0)
    }

    @Test func revisitsWithNoNotesHaveNoWrittenText() throws {
        let revisits = [Revisit(date: Make.day(9), outcome: .good, note: nil), Revisit(date: Make.day(12), outcome: .good, note: "  ")]
        let decision = Make.decision(actual: .neutral, notes: " ", reflection: nil, resolvedAt: Make.day(3), revisits: revisits)
        #expect(try #require(ReflectionDigestBuilder.decision(decision)).hasWrittenText == false)
    }

    @Test func anyOneNoteCountsAsWrittenText() throws {
        let logNote = Make.decision(actual: .good, notes: "Cheaper and closer.", resolvedAt: Make.day(3))
        let revisitNote = Make.decision(actual: .good, notes: nil, resolvedAt: Make.day(3), revisits: [Revisit(date: Make.day(9), outcome: .good, note: "Still glad.")])
        #expect(try #require(ReflectionDigestBuilder.decision(logNote)).hasWrittenText)
        #expect(try #require(ReflectionDigestBuilder.decision(revisitNote)).hasWrittenText)
    }
}
