import Foundation

struct SavedReflection: Codable, Equatable, Identifiable {
    enum Kind: Codable, Equatable, Hashable {
        case patterns
        case decision(UUID)
        var title: String {
            switch self { case .patterns: "Patterns"; case .decision: "How it aged" }
        }
    }
    let id: UUID
    let generatedAt: Date
    let kind: Kind
    let summary: String
    let observations: [ReflectionObservation]
    let snapshot: ReflectionSourceSnapshot

    init(id: UUID = UUID(), generatedAt: Date = Date(), kind: Kind, summary: String,
         observations: [ReflectionObservation], snapshot: ReflectionSourceSnapshot) {
        self.id = id
        self.generatedAt = Date(timeIntervalSince1970: generatedAt.timeIntervalSince1970.rounded(.down))
        self.kind = kind
        self.summary = summary
        self.observations = observations
        self.snapshot = snapshot
    }

    func validate() throws {
        try snapshot.validate()
        guard Set(observations.map(\.id)).count == observations.count else { throw ReflectionError.failed }
        switch kind {
        case .patterns:
            guard !observations.isEmpty else { throw ReflectionError.emptyOutput }
            for observation in observations { _ = try observation.validated(against: snapshot, minimumDecisions: 2) }
        case .decision(let id):
            guard snapshot.subjectID == id, snapshot.decisions.contains(where: { $0.id == id }), !summary.isEmpty else { throw ReflectionError.failed }
            for observation in observations { _ = try observation.validated(against: snapshot, minimumDecisions: 1) }
        }
    }
}
