import Foundation
import Testing
@testable import Offshoots

@MainActor
struct ReflectionHistoryStoreTests {
    func location() throws -> URL {
        let dir = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("reflections.json")
    }
    func sample() -> SavedReflection {
        let decision = Make.decision(actual: .bad, notes: "Agreed immediately")
        return SavedReflection(kind: .decision(decision.id), summary: "First outcome: Bad.", observations: [],
                               snapshot: .capture(decisions: [decision], subjectID: decision.id))
    }
    @Test func refreshAppendsImmutableReadingsAndRelaunchRestores() throws {
        let url = try location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = ReflectionHistoryStore(saveURL: url)
        let first = sample()
        var second = first
        second = SavedReflection(kind: first.kind, summary: "New reading", observations: [], snapshot: first.snapshot)
        try store.append(first)
        try store.append(second)
        let loaded = ReflectionHistoryStore(saveURL: url)
        #expect(loaded.readings.count == 2)
        #expect(loaded.readings.contains(first))
        #expect(Set(loaded.readings.map(\.id)).count == 2)
    }
    @Test func failedWriteRetainsDiskAndMemory() throws {
        let url = try location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = ReflectionHistoryStore(saveURL: url)
        let first = sample()
        try store.append(first)
        store.write = { _,_ in throw CocoaError(.fileWriteNoPermission) }
        #expect(throws: (any Error).self) { try store.append(sample()) }
        #expect(throws: (any Error).self) { try store.delete(id: first.id) }
        #expect(store.readings == [first])
        #expect(ReflectionHistoryStore(saveURL: url).readings == [first])
    }
    @Test func corruptFileBlocksOverwriteAndIsRecoverable() throws {
        let url = try location()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let bytes = Data("broken".utf8)
        try bytes.write(to: url)
        let store = ReflectionHistoryStore(saveURL: url)
        #expect(store.loadError != nil)
        #expect(throws: (any Error).self) { try store.append(sample()) }
        #expect(try store.recoveryData() == bytes)
    }
    @Test func freshnessFindsEditsMissingAndAddedDecisions() {
        let reading = sample()
        var source = reading.snapshot.decisions[0]
        source.notes = "Edited"
        let added = Make.decision(actual: .good, notes: "New entry")
        let pattern = SavedReflection(kind: .patterns, summary: "", observations: [], snapshot: reading.snapshot)
        let status = ReflectionFreshness.status(for: pattern, decisions: [source,added])
        #expect(status.changed == [source.id])
        #expect(status.added == [added.id])
        #expect(ReflectionFreshness.status(for: reading, decisions: []).missing == [source.id])
        #expect(reading.snapshot.decisions[0].notes == "Agreed immediately")
    }
}
