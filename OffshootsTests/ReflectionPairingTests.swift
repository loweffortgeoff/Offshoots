import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionPairingTests {
    /// Notes that share a marker word read alike; everything else does not
    private func marked(_ notes: [String]) -> (String, String) -> Double {
        { a, b in a.contains("rushed") && b.contains("rushed") ? 0.9 : 0.1 }
    }

    @Test func thePairComesFromTwoDecisionsWhoseNotesReadAlike() throws {
        let a = Make.decision(actual: .bad, notes: "rushed the purchase", createdAt: Make.day(3))
        let b = Make.decision(actual: .good, notes: "Took my time", createdAt: Make.day(2))
        let c = Make.decision(actual: .bad, notes: "rushed into saying yes", createdAt: Make.day(1))
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [a, b, c], subjectID: nil)
        let pairs = ReflectionPairing.pairs(in: snapshot, similarity: marked)
        let pair = try #require(pairs.first)
        #expect(pairs.count == 1)
        #expect(Set([pair.firstKey, pair.secondKey]) == ["R1.log", "R3.log"])
        #expect(pair.reasons == ["both went worse than predicted"])
    }

    @Test func notesFromOneDecisionNeverPair() {
        let a = Make.decision(actual: .bad, notes: "rushed it", reflection: "rushed again")
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [a], subjectID: nil)
        #expect(ReflectionPairing.pairs(in: snapshot, similarity: marked).isEmpty)
    }

    @Test func aSharedHindsightAnswerRanksAPairHigher() throws {
        var a = Make.decision(actual: .bad, notes: "rushed one", createdAt: Make.day(4))
        // Worse, better and as predicted: no shared direction, so only the answers can rank
        var b = Make.decision(actual: .veryGood, notes: "rushed two", createdAt: Make.day(3))
        let c = Make.decision(actual: .good, notes: "rushed three", createdAt: Make.day(2))
        a.hindsight = .differentChoice
        b.hindsight = .differentApproach
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [a, b, c], subjectID: nil)
        let top = try #require(ReflectionPairing.pairs(in: snapshot, similarity: marked).first)
        #expect(Set([top.firstKey, top.secondKey]) == ["R1.log", "R2.log"])
        #expect(top.reasons.contains("both hindsight answers would change something"))
    }

    @Test func thePromptHoldsOnlyTheTwoNotesAndNoSharedFacts() throws {
        let a = Make.decision(title: "Laptop", actual: .bad, notes: "rushed the purchase", reflection: "Did not need it", createdAt: Make.day(2))
        let b = Make.decision(title: "Committee", actual: .bad, notes: "rushed into saying yes", createdAt: Make.day(1))
        let snapshot = ReflectionSourceSnapshot.capture(decisions: [a, b], subjectID: nil)
        let pair = try #require(ReflectionPairing.pairs(in: snapshot, similarity: marked).first)
        let prompt = ReflectionPromptBuilder.pairPrompt(pair, snapshot: snapshot)
        #expect(prompt.contains("[R1.log] Laptop: rushed the purchase"))
        #expect(prompt.contains("[R2.log] Committee: rushed into saying yes"))
        #expect(!prompt.contains("Did not need it"))
        #expect(!prompt.contains("worse than predicted"))
    }

    @Test func sharedWordsIgnoreShortWords() {
        #expect(NoteSimilarity.sharedWords("bought it in a hurry", "signed in a hurry") == 1.0 / 3.0)
        #expect(NoteSimilarity.sharedWords("", "") == 0)
    }
}
