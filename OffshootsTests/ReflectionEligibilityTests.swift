import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionEligibilityTests {

    // MARK: - Patterns

    @Test func patternsNeedTwoDistinctNotedMarkedDecisions() {
        let a = Make.decision(actual: .good, notes: "First", reflection: "Second")
        let b = Make.decision(actual: .bad, notes: "Another decision")
        #expect(!ReflectionEligibility.canShowPatterns(for: [a,a]))
        #expect(!ReflectionEligibility.hasNotesForPatterns([a]))
        #expect(ReflectionEligibility.canShowPatterns(for: [a,b]))
    }
    @Test func pendingAndBlankNotesDoNotQualify() {
        let a = Make.decision(actual: .good, notes: "Only marked note")
        #expect(!ReflectionEligibility.hasNotesForPatterns([a,Make.decision(notes: "Pending")]))
        #expect(!ReflectionEligibility.hasNotesForPatterns([a,Make.decision(actual: .good, notes: "  ")]))
        let b = Make.decision(actual: .good, revisits: [Revisit(outcome: .bad, note: "Later note")])
        #expect(ReflectionEligibility.hasNotesForPatterns([a,b]))
    }

    // MARK: - Decision reflection

    @Test func pendingDecisionCannotBeReflectedOn() {
        #expect(ReflectionEligibility.canReflect(on: Make.decision(notes: "Some note")) == false)
    }

    @Test func markedDecisionWithNothingToReadIsNotEligible() {
        #expect(ReflectionEligibility.canReflect(on: Make.marked()) == false)
    }

    @Test func markedDecisionWithAnyNoteOrRevisitIsEligible() {
        #expect(ReflectionEligibility.canReflect(on: Make.decision(actual: .good, notes: "Why I chose it")))
        #expect(ReflectionEligibility.canReflect(on: Make.decision(actual: .good, reflection: "What happened")))
        // A revisit counts even with no note on it
        let revisit = Revisit(date: Make.day(20), outcome: .bad, note: nil)
        #expect(ReflectionEligibility.canReflect(on: Make.decision(actual: .good, revisits: [revisit])))
    }

    @Test func whitespaceOnlyNotesCountAsNoNote() {
        let decision = Make.decision(actual: .good, notes: "  \n ", reflection: "\t")
        #expect(ReflectionEligibility.canReflect(on: decision) == false)
    }

    // MARK: - Clean Up Note

    @Test func cleanUpNeedsThreeWords() {
        #expect(ReflectionEligibility.cleanUpStatus("") == .tooShort)
        #expect(ReflectionEligibility.cleanUpStatus("Too   short") == .tooShort)
        #expect(ReflectionEligibility.cleanUpStatus("Chose the safer job") == .ok)
    }

    @Test func cleanUpRefusesAVeryLongNote() {
        let long = String(repeating: "word ", count: 2_000)
        #expect(ReflectionEligibility.cleanUpStatus(long) == .tooLong)
    }

    @Test func cleanUpLimitIsInclusive() {
        let atLimit = String(repeating: "a ", count: 749) + "bb" // 1,500 characters
        #expect(atLimit.count == 1_500)
        #expect(ReflectionEligibility.cleanUpStatus(atLimit) == .ok)
        #expect(ReflectionEligibility.cleanUpStatus(atLimit + "c") == .tooLong)
    }
}
