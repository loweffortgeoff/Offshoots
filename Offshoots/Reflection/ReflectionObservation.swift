import Foundation

struct ReflectionObservation: Codable, Equatable, Identifiable {
    var id = UUID()
    let text: String
    let evidenceKeys: [String]

    func validated(against snapshot: ReflectionSourceSnapshot, minimumDecisions: Int) throws -> Self {
        let known = Dictionary(uniqueKeysWithValues: snapshot.evidence.map { ($0.key, $0) })
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !evidenceKeys.isEmpty, Set(evidenceKeys).count == evidenceKeys.count,
              evidenceKeys.allSatisfy({ known[$0] != nil }),
              Set(evidenceKeys.compactMap { known[$0]?.decisionID }).count >= minimumDecisions
        else { throw ReflectionError.emptyOutput }
        // Recurring observations need written evidence from every supporting decision.
        if minimumDecisions > 1 {
            let written = Set(evidenceKeys.compactMap { known[$0] }.filter { $0.stage != .record }.map(\.decisionID))
            guard written.count >= minimumDecisions else { throw ReflectionError.emptyOutput }
        }
        return self
    }
    func validatedChange(against snapshot: ReflectionSourceSnapshot, subjectID: UUID) throws -> Self {
        let value = try validated(against: snapshot, minimumDecisions: 1)
        let ordered = evidenceKeys.compactMap { key in snapshot.evidence.first { $0.key == key } }
        guard ordered.count == 2, ordered.allSatisfy({ $0.decisionID == subjectID }),
              ordered[0].date <= ordered[1].date else { throw ReflectionError.emptyOutput }
        return value
    }

}
