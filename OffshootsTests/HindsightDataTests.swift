import Foundation
import Testing
@testable import Offshoots

@MainActor
struct HindsightDataTests {
    @Test func legacyFilesHaveNoAnswer() throws {
        #expect(try Fixture.load("reflection-notes").allSatisfy { $0.hindsight == nil && $0.revisits.allSatisfy { $0.hindsight == nil } })
    }

    @Test(arguments: HindsightAnswer.allCases)
    func roundTripEveryAnswer(answer: HindsightAnswer) throws {
        var d = Make.marked(.good, .bad)
        d.hindsight = answer
        d.reflection = "Would spread the work out."
        d.revisits = [Revisit(date: Make.day(10), outcome: .good, note: "Kept the change.", hindsight: answer),
                      Revisit(date: Make.day(11), outcome: .neutral)]
        let data = try DecisionStore.encode([d])
        #expect(try DecisionStore.decode(data) == [d])
        #expect(try ReflectionBackup.decode(ReflectionBackup.encode(decisions: [d], readings: [])).decisions == [d])
    }

    @Test func storeCapturesAndReloadsEachEvent() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("decisions.json")
        let store = DecisionStore(saveURL: url)
        let d = Make.decision()
        store.add(d)
        store.resolveDecision(id: d.id, actual: .bad, reflection: "Guilty", hindsight: .differentApproach)
        store.addRevisit(id: d.id, outcome: .good, note: "Useful", hindsight: .sameApproach)
        store.addRevisit(id: d.id, outcome: .neutral)
        store.waitForPendingSaves()
        let reloaded = DecisionStore(saveURL: url)
        let saved = try #require(reloaded.decisions.first)
        #expect(saved.hindsight == .differentApproach)
        #expect(saved.reflection == "Guilty")
        #expect(saved.revisits.map(\.hindsight) == [.sameApproach, nil])
        var edited = saved
        edited.title = "New title"
        reloaded.update(edited)
        reloaded.waitForPendingSaves()
        #expect(DecisionStore(saveURL: url).decisions.first?.hindsight == .differentApproach)
        reloaded.delete(edited)
        reloaded.waitForPendingSaves()
        #expect(DecisionStore(saveURL: url).decisions.isEmpty)
    }

    @Test func unknownAnswersAreRejectedBeforeImport() throws {
        var d = Make.marked()
        d.hindsight = .notSure
        let data = try DecisionStore.encode([d])
        let invalid = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: "notSure", with: "unknownAnswer").utf8)
        #expect(throws: (any Error).self) { try DecisionStore.decode(invalid) }
        let backup = try ReflectionBackup.encode(decisions: [d], readings: [])
        let invalidBackup = Data(String(decoding: backup, as: UTF8.self).replacingOccurrences(of: "notSure", with: "unknownAnswer").utf8)
        #expect(throws: (any Error).self) { try ReflectionBackup.decode(invalidBackup) }
        d.hindsight = nil
        d.revisits = [Revisit(outcome: .good, hindsight: .notSure)]
        let invalidRevisit = Data(String(decoding: try DecisionStore.encode([d]), as: UTF8.self).replacingOccurrences(of: "notSure", with: "unknownAnswer").utf8)
        #expect(throws: (any Error).self) { try DecisionStore.decode(invalidRevisit) }
    }

    @Test func hindsightDoesNotChangeFreeAnalyticsOrModelPrompt() {
        var a = Make.decision(actual: .bad, notes: "Signed quickly.", reflection: "Cost too much.")
        let b = Make.decision(actual: .good, notes: "Checked quotes.", reflection: "Worked well.")
        let before = ReflectionPromptBuilder.patternsPrompt(ReflectionDigestBuilder.patterns(from: [a, b]))
        let accuracy = AnalyticsEngine.predictionGap(for: a)
        a.hindsight = .sameApproach
        #expect(ReflectionPromptBuilder.patternsPrompt(ReflectionDigestBuilder.patterns(from: [a, b])) == before)
        #expect(AnalyticsEngine.predictionGap(for: a) == accuracy)
        #expect(a.currentOutcome == .bad)
    }
}
