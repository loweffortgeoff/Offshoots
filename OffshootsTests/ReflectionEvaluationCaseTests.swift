import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionEvaluationCaseTests {
    private func encoded(_ cases: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: cases)
    }
    private var valid: [String: Any] {
        ["id": "one", "surface": "patterns", "decisions": [], "eligible": false,
         "expectedDecisionIDs": [], "prohibitedFacts": [], "rubric": "Abstain", "synthetic": true]
    }
    @Test func corpusHasThirtyToFiftyScoredCases() throws {
        final class BundleToken {}
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "reflection-acceptance", withExtension: "json"))
        let cases = try ReflectionEvaluationCase.load(from: Data(contentsOf: url))
        #expect((30...50).contains(cases.count))
        #expect(cases.allSatisfy { !$0.rubric.isEmpty })
    }
    @Test func rejectsDuplicateIDs() throws {
        #expect(throws: (any Error).self) { try ReflectionEvaluationCase.load(from: encoded([valid, valid])) }
    }
    @Test func rejectsUnknownExpectedEvidence() throws {
        var value = valid
        value["expectedDecisionIDs"] = [UUID().uuidString]
        #expect(throws: (any Error).self) { try ReflectionEvaluationCase.load(from: encoded([value])) }
    }
    @Test func requiresExplicitEligibility() throws {
        var value = valid
        value.removeValue(forKey: "eligible")
        #expect(throws: (any Error).self) { try ReflectionEvaluationCase.load(from: encoded([value])) }
    }
    @Test func threeNotesOnOneDecisionAreNotCrossDecisionSupport() {
        let value = Make.decision(actual: .good, notes: "Original note", reflection: "Outcome note",
                                  revisits: [Revisit(outcome: .bad, note: "Later note")])
        #expect(ReflectionEvaluationCase.distinctNotedDecisions([value, value]) == 1)
    }
}
