import Foundation
import Observation

@Observable
final class ReflectionHistoryStore {
    struct Envelope: Codable { var version = 1; let readings: [SavedReflection] }
    private(set) var readings: [SavedReflection] = []
    private(set) var loadError: String?
    @ObservationIgnored let saveURL: URL
    @ObservationIgnored var write: (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }

    init(saveURL: URL = URL.documentsDirectory.appendingPathComponent("reflections.json")) {
        self.saveURL = saveURL
        if FileManager.default.fileExists(atPath: saveURL.path) {
            do { readings = try Self.decode(Data(contentsOf: saveURL)) }
            catch { loadError = "Saved reflections could not be opened. Export the recovery file before restoring a full backup." }
        }
    }

    static func encode(_ readings: [SavedReflection]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(Envelope(readings: readings))
    }
    static func decode(_ data: Data) throws -> [SavedReflection] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(Envelope.self, from: data)
        guard envelope.version == 1, Set(envelope.readings.map(\.id)).count == envelope.readings.count else { throw ReflectionError.failed }
        for reading in envelope.readings { try reading.validate() }
        return envelope.readings
    }
    func append(_ reading: SavedReflection) throws {
        try reading.validate()
        guard !readings.contains(where: { $0.id == reading.id }) else { throw ReflectionError.failed }
        try replaceAll(with: readings + [reading])
    }
    func delete(id: UUID) throws { try replaceAll(with: readings.filter { $0.id != id }) }
    func replaceAll(with values: [SavedReflection]) throws {
        guard loadError == nil else { throw ReflectionError.failed }
        let bytes = try Self.encode(values)
        _ = try Self.decode(bytes)
        try write(bytes, saveURL)
        readings = values
    }
    func recoveryData() throws -> Data { try Data(contentsOf: saveURL) }

    /// Only called by the completed coordinated restore after both files are durable.
    func publishRestored(_ values: [SavedReflection]) {
        readings = values
        loadError = nil
    }
}
