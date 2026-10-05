import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionDigestBuilderTests {

    // MARK: - Patterns

    @Test func patternsDigestSplitsByTheFirstResult() throws {
        let digest = ReflectionDigestBuilder.patterns(from: try Fixture.load("reflection-notes"))

        #expect(digest.resolvedCount == 17)
        #expect(digest.worseCount == 6)
        #expect(digest.asPredictedCount == 4)
        #expect(digest.betterCount == 7)
        // Six decisions with a log note and an outcome note, plus one revisit note
        #expect(digest.worse.count == 13)
        #expect(digest.worse.first == NoteLine(category: "Relationships", stakes: "Medium", text: "Made it worse. I had to apologize the next day."))
    }

    @Test func aRevisitNoteStaysInItsDecisionsFirstResultGroup() {
        let revisit = Revisit(date: Make.day(20), outcome: .veryGood, note: "Much better now")
        let decision = Make.decision(expected: .good, actual: .bad, resolvedAt: Make.day(7), revisits: [revisit])
        let digest = ReflectionDigestBuilder.patterns(from: [decision])

        #expect(digest.worse.map(\.text) == ["Much better now"])
        #expect(digest.better.isEmpty)
    }

    @Test func eachGroupIsCappedNewestFirst() {
        var decisions = (0..<20).map { index in
            Make.decision(expected: .good, actual: .bad, notes: "Worse \(index)", createdAt: Make.day(index), resolvedAt: Make.day(index + 1))
        }
        decisions.append(Make.decision(expected: .bad, actual: .good, notes: "Better", resolvedAt: Make.day(2)))
        decisions.append(Make.decision(actual: .good, notes: "   \n", resolvedAt: Make.day(3)))

        let digest = ReflectionDigestBuilder.patterns(from: decisions)
        #expect(digest.worse.count == ReflectionDigestBuilder.notesPerGroup)
        #expect(digest.worse.first?.text == "Worse 19")
        // The full group does not push out the small one, and a blank note is dropped
        #expect(digest.better.map(\.text) == ["Better"])
        #expect(digest.asPredicted.isEmpty)
    }

    @Test func pendingDecisionsAreLeftOut() {
        let digest = ReflectionDigestBuilder.patterns(from: [Make.decision(notes: "Not marked yet")])
        #expect(digest.resolvedCount == 0)
        #expect(digest.noteCount == 0)
    }

    @Test func aHugeNoteIsCutInTheDigest() throws {
        let decisions = [Make.decision(actual: .good, notes: String(repeating: "word ", count: 5_000), resolvedAt: Make.day(2))]
        let note = try #require(ReflectionDigestBuilder.patterns(from: decisions).asPredicted.first)
        #expect(note.text.count == ReflectionDigestBuilder.noteLimit)
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
