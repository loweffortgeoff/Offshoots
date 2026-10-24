import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionEvidenceTests {
    @Test func repeatedNotesAreOneDecision() throws {
        let one = Make.decision(actual: .bad, notes: "Bought it fast", reflection: "Did not need it")
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [one], subjectID: nil)
        let keys = snapshot.evidence.map(\.key)
        #expect(throws: (any Error).self) {
            try ReflectionObservation(text: "These choices were rushed.", evidenceKeys: keys).validated(against: snapshot, minimumDecisions: 2)
        }
    }
    @Test func crossCategorySourcesAreSupportedAndUnknownKeysRejected() throws {
        let a = Make.decision(category: .money, actual: .bad, notes: "Bought it immediately")
        let b = Make.decision(category: .work, actual: .bad, notes: "Agreed immediately")
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [a,b], subjectID: nil)
        let keys = snapshot.evidence.filter { $0.stage == .log }.map(\.key)
        let result = try ReflectionObservation(text: "Both notes describe an immediate commitment.", evidenceKeys: keys).validated(against: snapshot, minimumDecisions: 2)
        #expect(result.evidenceKeys.count == 2)
        #expect(throws: (any Error).self) { try ReflectionObservation(text: "Unknown", evidenceKeys: ["missing"]).validated(against: snapshot, minimumDecisions: 1) }
        #expect(throws: (any Error).self) { try ReflectionObservation(text: "Duplicate", evidenceKeys: [keys[0],keys[0]]).validated(against: snapshot, minimumDecisions: 2) }
    }
    @Test func snapshotPreservesChronologyAndOmitsWholeLongRecords() {
        let revisit = Revisit(date: Make.day(20), outcome: .good, note: "Better now")
        let a = Make.decision(expected: .good, actual: .bad, notes: "Chose quickly", revisits: [revisit])
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [a], subjectID: a.id)
        #expect(snapshot.decisions.first?.actual == .bad)
        #expect(snapshot.decisions.first?.revisits.first?.outcome == .good)
        let huge = Make.decision(actual: .good, notes: String(repeating: "word ",count: 5000))
        let capped = ReflectionSourceSnapshot.capture(decisions: [huge,a], subjectID: nil)
        #expect(!capped.decisions.contains { $0.id == huge.id })
        #expect(capped.omittedCount == 1)
    }
    @Test func tiedDatesHaveStableSelection() {
        let a = Make.decision(actual: .good, notes: "One", createdAt: Make.day(1))
        let b = Make.decision(actual: .bad, notes: "Two", createdAt: Make.day(1))
        #expect(ReflectionSourceSnapshot.capture(decisions: [a,b], subjectID: nil) == ReflectionSourceSnapshot.capture(decisions: [b,a], subjectID: nil))
    }
}
