import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionEligibilityTests {

    // MARK: - Patterns

    @Test func patternsNeedFiveMarkedDecisions() {
        let four = Array(repeating: Make.marked(), count: 4)
        let five = Array(repeating: Make.marked(), count: 5)
        #expect(ReflectionEligibility.canShowPatterns(for: four) == false)
        #expect(ReflectionEligibility.canShowPatterns(for: five) == true)
    }

    @Test func patternsNeedTwoNotesOnMarkedDecisions() {
        let one = [Make.decision(actual: .good, notes: "Only one", resolvedAt: Make.day(7))]
        let two = [Make.decision(actual: .good, notes: "First", reflection: "Second", resolvedAt: Make.day(7))]
        #expect(ReflectionEligibility.hasNotesForPatterns(one) == false)
        #expect(ReflectionEligibility.hasNotesForPatterns(two) == true)
    }

    @Test func revisitNotesCountAndBlankOrPendingNotesDoNot() {
        let revisit = Revisit(date: Make.day(9), outcome: .good, note: "From a revisit")
        let marked = Make.decision(actual: .good, notes: "  ", resolvedAt: Make.day(7), revisits: [revisit])
        let pending = Make.decision(notes: "Pending note", reflection: "Another")
        #expect(ReflectionEligibility.hasNotesForPatterns([marked, pending]) == false)
        #expect(ReflectionEligibility.hasNotesForPatterns([marked, marked]) == true)
    }

    @Test func pendingDecisionsDoNotCountTowardPatterns() {
        let decisions = Array(repeating: Make.marked(), count: 4) + [Make.decision()]
        #expect(ReflectionEligibility.canShowPatterns(for: decisions) == false)
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
