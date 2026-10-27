import Foundation

/// Replaces the two JSON files as one recoverable operation. A remaining marker rolls back at launch.
@MainActor
final class JournalDataCoordinator {
    private struct Marker: Codable {
        let version: Int
        let decisions: Data?
        let readings: Data?
    }
    private let store: DecisionStore
    private let history: ReflectionHistoryStore
    var write: (Data,URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }
    init(store: DecisionStore, history: ReflectionHistoryStore) { self.store = store; self.history = history }

    static func recover(directory: URL) throws {
        let markerURL = directory.appendingPathComponent("journal-restore.json")
        guard FileManager.default.fileExists(atPath: markerURL.path) else { return }
        let marker = try JSONDecoder().decode(Marker.self, from: Data(contentsOf: markerURL))
        guard marker.version == 1 else { throw ReflectionError.failed }
        for (name,data) in [("decisions.json",marker.decisions),("reflections.json",marker.readings)] {
            let url = directory.appendingPathComponent(name)
            if let data { try data.write(to: url, options: .atomic) }
            else if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        }
        try FileManager.default.removeItem(at: markerURL)
    }
    func restore(_ backup: ReflectionBackup) throws {
        try backup.validate()
        store.waitForPendingSaves()
        let directory = store.saveURL.deletingLastPathComponent()
        guard directory.standardizedFileURL == history.saveURL.deletingLastPathComponent().standardizedFileURL,
              store.saveURL.lastPathComponent == "decisions.json", history.saveURL.lastPathComponent == "reflections.json"
        else { throw ReflectionError.failed }
        try Self.recover(directory: directory)
        // The marker is deleted on success, so it cannot be the only copy of a file the app could not read.
        if history.loadError != nil, FileManager.default.fileExists(atPath: history.saveURL.path) {
            let aside = directory.appendingPathComponent("reflections-unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try FileManager.default.copyItem(at: history.saveURL, to: aside)
        }
        // `backup.validate()` already checked the readings; encoding cannot make them invalid.
        let decisionData = try DecisionStore.encode(backup.decisions)
        let historyData = try ReflectionHistoryStore.encode(backup.readings)
        func oldData(_ url: URL) throws -> Data? {
            FileManager.default.fileExists(atPath: url.path) ? try Data(contentsOf: url) : nil
        }
        let marker = Marker(version: 1, decisions: try oldData(store.saveURL), readings: try oldData(history.saveURL))
        let markerURL = directory.appendingPathComponent("journal-restore.json")
        try write(JSONEncoder().encode(marker), markerURL)
        do {
            try write(decisionData, store.saveURL)
            try write(historyData, history.saveURL)
            try FileManager.default.removeItem(at: markerURL)
        } catch {
            // Leave the marker if rollback itself fails; launch recovery must complete before editing.
            do { try Self.recover(directory: directory) }
            catch { store.blockAfterRestoreFailure() }
            throw error
        }
        store.publishRestored(backup.decisions)
        history.publishRestored(backup.readings)
    }
    func importDecisions(_ decisions: [Decision]) throws { try restore(ReflectionBackup(decisions: decisions, readings: [])) }
    func deleteAll() throws { try restore(ReflectionBackup(decisions: [], readings: [])) }
}
