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

    @Test func historyHoldsOtherMarkedDecisionsInTheSameCategory() throws {
        let decisions = try Fixture.load("reflection-notes")
        let laptop = try #require(decisions.first { $0.title == "Upgrade to the new laptop" })
        let digest = try #require(ReflectionDigestBuilder.decision(laptop, among: decisions))

        // Four other marked Money decisions, newest first. The open couch decision is left out.
        #expect(digest.history.map(\.title) == [
            "Sell the old bike",
            "Buy concert tickets for the whole group",
            "Refinance the car loan",
            "Sign up for the annual gym plan",
        ])
        #expect(digest.history.last == HistoryLine(
            title: "Sign up for the annual gym plan",
            stakes: "Medium",
            direction: -1,
            notes: "The salesperson said the price goes up tomorrow, so I signed on the spot.",
            outcomeNote: "Went four times. Paid for a whole year."
        ))
    }

    @Test func historySplitsIntoSameAndDifferentResults() throws {
        let decisions = try Fixture.load("reflection-notes")
        let laptop = try #require(decisions.first { $0.title == "Upgrade to the new laptop" })
        let digest = try #require(ReflectionDigestBuilder.decision(laptop, among: decisions))

        #expect(digest.direction == -1)
        #expect(digest.sameResult.map(\.title) == ["Buy concert tickets for the whole group", "Sign up for the annual gym plan"])
        #expect(digest.differentResult.map(\.title) == ["Sell the old bike", "Refinance the car loan"])
    }

    @Test func historyIsCappedNewestFirst() {
        let others = (0..<8).map { Make.decision(title: "Other \($0)", actual: .good, createdAt: Make.day($0), resolvedAt: Make.day($0 + 1)) }
        let history = ReflectionDigestBuilder.history(in: .work, from: others)
        #expect(history.count == ReflectionDigestBuilder.historyLimit)
        #expect(history.first?.title == "Other 7")
    }

    @Test func oneOtherDecisionIsNotAHistory() throws {
        let decision = Make.decision(actual: .bad, resolvedAt: Make.day(7))
        let one = [Make.decision(title: "Only one", actual: .good, resolvedAt: Make.day(7))]
        let otherCategory = (0..<3).map { _ in Make.decision(category: .money, actual: .good, resolvedAt: Make.day(7)) }
        #expect(try #require(ReflectionDigestBuilder.decision(decision, among: one + otherCategory)).history.isEmpty)
    }

    @Test func theDecisionItselfIsNotInItsHistory() throws {
        let decision = Make.decision(title: "Itself", actual: .bad, resolvedAt: Make.day(7))
        let others = [decision, Make.decision(title: "A", actual: .good, resolvedAt: Make.day(7)), Make.decision(title: "B", actual: .good, resolvedAt: Make.day(7))]
        let digest = try #require(ReflectionDigestBuilder.decision(decision, among: others))
        #expect(!digest.history.map(\.title).contains("Itself"))
        #expect(digest.history.count == 2)
    }

    // MARK: - Look Back

    @Test func lookBackSummaryCountsEachResult() throws {
        let digest = try #require(ReflectionDigestBuilder.lookBack(category: .money, in: try Fixture.load("reflection-notes")))
        #expect(digest.history.count == 5)
        #expect(digest.stats.summary == "Of the 5 Money decisions you marked, 3 went worse than you predicted, 1 went as predicted and 1 went better.")
        #expect(digest.stats.headline == "Your Money decisions tend to fall short of your predictions")
    }

    @Test func lookBackSummaryWithOneResultHasNoList() throws {
        let decisions = (0..<2).map { _ in Make.decision(expected: .bad, actual: .good, resolvedAt: Make.day(7)) }
        let digest = try #require(ReflectionDigestBuilder.lookBack(category: .work, in: decisions))
        #expect(digest.stats.summary == "Of the 2 Work decisions you marked, 2 went better.")
        #expect(digest.hasNotes == false)
    }

    /// Seen 2026-10-14: a note-less "as predicted" group got an invented sentence
    @Test func lookBackGroupWithoutNotesGetsNoSentence() throws {
        let decisions = [
            Make.decision(expected: .bad, actual: .good, notes: "Some sites will be closed.", reflection: "Nothing disastrous happened", resolvedAt: Make.day(7)),
            Make.decision(expected: .neutral, actual: .neutral, resolvedAt: Make.day(7)),
        ]
        let digest = try #require(ReflectionDigestBuilder.lookBack(category: .work, in: decisions))
        #expect(digest.betterHasNotes)
        #expect(!digest.asPredictedHasNotes)
        #expect(!digest.worseHasNotes)
    }

    /// The prompt keeps the 5 newest; the counts and bars cover every marked decision
    @Test func lookBackStatsCoverEveryMarkedDecisionInTheCategory() throws {
        let decisions = (0..<8).map { _ in Make.decision(expected: .bad, actual: .good, resolvedAt: Make.day(7)) }
            + [Make.decision(), Make.decision(category: .money, actual: .good, resolvedAt: Make.day(7))]
        let digest = try #require(ReflectionDigestBuilder.lookBack(category: .work, in: decisions))
        #expect(digest.history.count == ReflectionDigestBuilder.historyLimit)
        #expect(digest.stats.total == 8)
    }

    @Test func lookBackNeedsTwoMarkedDecisionsInTheCategory() {
        let decisions = [
            Make.decision(actual: .good, resolvedAt: Make.day(7)),
            Make.decision(),
            Make.decision(category: .money, actual: .good, resolvedAt: Make.day(7)),
        ]
        #expect(ReflectionDigestBuilder.lookBack(category: .work, in: decisions) == nil)
    }

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
