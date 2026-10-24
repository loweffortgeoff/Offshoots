import Foundation

/// Offline evaluation inputs. Never written to a user's saved-reading store.
struct ReflectionEvaluationCase: Codable, Equatable, Identifiable {
    let id: String
    let surface: String
    let decisions: [Decision]
    let eligible: Bool
    let expectedDecisionIDs: [UUID]
    let prohibitedFacts: [String]
    let rubric: String
    let synthetic: Bool
    var note: String?

    static func load(from data: Data) throws -> [Self] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cases = try decoder.decode([Self].self, from: data)
        guard Set(cases.map(\.id)).count == cases.count,
              cases.allSatisfy({ value in
                  !value.id.isEmpty && ["patterns", "decision", "cleanup"].contains(value.surface) &&
                  Set(value.decisions.map(\.id)).count == value.decisions.count &&
                  Set(value.expectedDecisionIDs).isSubset(of: Set(value.decisions.map(\.id)))
              }) else { throw CocoaError(.coderReadCorrupt) }
        return cases
    }

    static func distinctNotedDecisions(_ decisions: [Decision]) -> Int {
        Set(decisions.filter { decision in
            decision.actual != nil && ([decision.notes, decision.reflection] + decision.revisits.map(\.note))
                .contains { $0?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        }.map(\.id)).count
    }
}
