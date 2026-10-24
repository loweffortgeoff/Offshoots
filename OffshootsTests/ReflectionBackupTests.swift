import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionBackupTests {
    @Test func roundTripAndLegacyRemainSeparate() throws {
        var d = Make.decision(actual: .good, notes: "A note")
        d.hindsight = .differentChoice
        let reading = SavedReflection(kind: .decision(d.id), summary: "Good first outcome", observations: [], snapshot: .capture(decisions: [d], subjectID: d.id))
        let bytes = try ReflectionBackup.encode(decisions: [d], readings: [reading])
        let result = try ReflectionBackup.decode(bytes)
        #expect(result.readings == [reading])
        #expect(result.decisions == [d])
        #expect(throws: (any Error).self) { try ReflectionBackup.decode(DecisionStore.encode([d])) }
        #expect(try DecisionStore.decode(DecisionStore.encode([d])) == [d])
    }
    @Test func duplicatesUnknownVersionsAndInvalidEvidenceAreRejected() throws {
        let d = Make.decision(actual: .good, notes: "A note")
        #expect(throws: (any Error).self) { try ReflectionBackup.encode(decisions: [d,d], readings: []) }
        var json = try #require(JSONSerialization.jsonObject(with: ReflectionBackup.encode(decisions: [d], readings: [])) as? [String:Any])
        json["version"] = 999
        #expect(throws: (any Error).self) { try ReflectionBackup.decode(JSONSerialization.data(withJSONObject: json)) }
        let bad = SavedReflection(kind: .decision(d.id), summary: "Reading", observations: [ReflectionObservation(text: "Bad link", evidenceKeys: ["unknown"])], snapshot: .capture(decisions: [d], subjectID: d.id))
        #expect(throws: (any Error).self) { try ReflectionBackup.encode(decisions: [d], readings: [bad]) }
    }
    @Test func failureBetweenFilesRecoversCoherentOriginalPair() throws {
        let folder = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = DecisionStore(saveURL: folder.appendingPathComponent("decisions.json"))
        let old = Make.decision(title: "Old", actual: .good, notes: "Original")
        store.add(old); store.waitForPendingSaves()
        let history = ReflectionHistoryStore(saveURL: folder.appendingPathComponent("reflections.json"))
        let reader = SavedReflection(kind: .decision(old.id), summary: "Old reading", observations: [], snapshot: .capture(decisions: [old], subjectID: old.id))
        try history.append(reader)
        let coordinator = JournalDataCoordinator(store: store, history: history)
        var writes = 0
        coordinator.write = { data,url in
            writes += 1
            if writes == 3 { throw CocoaError(.fileWriteNoPermission) }
            try data.write(to: url, options: .atomic)
        }
        let new = Make.decision(title: "New")
        #expect(throws: (any Error).self) { try coordinator.restore(ReflectionBackup(decisions: [new], readings: [])) }
        try JournalDataCoordinator.recover(directory: folder)
        #expect(try DecisionStore.decode(Data(contentsOf: store.saveURL)) == [old])
        #expect(ReflectionHistoryStore(saveURL: history.saveURL).readings == [reader])
        #expect(store.decisions == [old])
    }
    @Test func decisionOnlyImportAndDeleteAllClearHistoryAndChangeEpoch() throws {
        let folder = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = DecisionStore(saveURL: folder.appendingPathComponent("decisions.json"))
        let history = ReflectionHistoryStore(saveURL: folder.appendingPathComponent("reflections.json"))
        let coordinator = JournalDataCoordinator(store: store, history: history)
        let d = Make.decision(actual: .good, notes: "Original")
        let reader = SavedReflection(kind: .decision(d.id), summary: "Old reading", observations: [], snapshot: .capture(decisions: [d], subjectID: d.id))
        try coordinator.restore(ReflectionBackup(decisions: [d], readings: [reader]))
        let epoch = store.revision
        try coordinator.importDecisions([])
        #expect(history.readings.isEmpty)
        #expect(store.revision != epoch)
        try history.append(reader) // Deleted live sources are permitted in retained history.
        try coordinator.deleteAll()
        #expect(history.readings.isEmpty)
    }
}
