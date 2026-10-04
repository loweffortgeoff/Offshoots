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
