import Foundation

struct ReflectionBackup: Codable, Equatable {
    var version = 1
    let decisions: [Decision]
    let readings: [SavedReflection]

    static func encode(decisions: [Decision], readings: [SavedReflection]) throws -> Data {
        let value = Self(decisions: decisions, readings: readings)
        try value.validate()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(value)
    }
    static func decode(_ data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let value = try decoder.decode(Self.self, from: data)
        try value.validate()
        return value
    }
    func validate() throws {
        guard version == 1, Set(decisions.map(\.id)).count == decisions.count,
              Set(readings.map(\.id)).count == readings.count else { throw ReflectionError.failed }
        for reading in readings { try reading.validate() }
    }
}
