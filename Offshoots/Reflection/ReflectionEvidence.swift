import Foundation

struct ReflectionEvidence: Codable, Equatable, Identifiable {
    enum Stage: String, Codable { case record, log, outcome, revisit }
    let key: String
    let decisionID: UUID
    let stage: Stage
    let revisitID: UUID?
    let date: Date
    let text: String
    let containsWrittenNote: Bool
    var id: String { key }
}
