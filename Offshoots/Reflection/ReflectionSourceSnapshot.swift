import Foundation

/// Exact records selected for one request. Never truncates a note to fit a prompt.
struct ReflectionSourceSnapshot: Codable, Equatable {
    let decisions: [Decision]
    let eligibleDecisionIDs: [UUID]
    let subjectID: UUID?
    let omittedCount: Int

    static func capture(decisions: [Decision], subjectID: UUID?) -> Self {
        let normalized = (try? DecisionStore.decode(DecisionStore.encode(decisions))) ?? decisions
        var seen = Set<UUID>()
        let eligible = normalized.filter { $0.actual != nil && seen.insert($0.id).inserted }
            .sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt > $1.createdAt }
        let ordered = eligible.sorted { a,b in
            if a.id == subjectID { return b.id != subjectID }
            if b.id == subjectID { return false }
            return a.createdAt == b.createdAt ? a.id.uuidString < b.id.uuidString : a.createdAt > b.createdAt
        }
        var kept: [Decision] = []
        // Conservative UTF-8 bound for older models lacking token-count APIs.
        // Newer models also check instructions + schema + prompt + response at request time.
        for decision in ordered {
            let written = [decision.title, decision.notes, decision.reflection] + decision.revisits.map(\.note)
            guard !written.compactMap({ $0 }).contains(where: ReflectionText.looksLikeModelInstruction) else { continue }
            let candidate = Self(decisions: kept + [decision], eligibleDecisionIDs: [], subjectID: subjectID, omittedCount: 0)
            if candidate.prompt.utf8.count <= 1800 { kept.append(decision) }
        }
        return Self(decisions: kept, eligibleDecisionIDs: eligible.map(\.id).sorted { $0.uuidString < $1.uuidString },
                    subjectID: subjectID, omittedCount: eligible.count - kept.count)
    }

    var evidence: [ReflectionEvidence] {
        decisions.enumerated().flatMap { index,d -> [ReflectionEvidence] in
            let prefix = "R\(index + 1)"
            func item(_ suffix: String, _ stage: ReflectionEvidence.Stage, _ date: Date, _ text: String?, revisitID: UUID? = nil, containsWrittenNote: Bool = true) -> ReflectionEvidence? {
                guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return ReflectionEvidence(key: prefix + "." + suffix, decisionID: d.id, stage: stage, revisitID: revisitID, date: date, text: text, containsWrittenNote: containsWrittenNote)
            }
            var values = [item("record", .record, d.createdAt,
                "\(d.title) | \(d.category.rawValue) | expected \(d.expected.shortLabel), first \(d.actual?.shortLabel ?? "unmarked") on \(d.resolvedDate?.ISO8601Format() ?? "unknown date")", containsWrittenNote: false),
                item("log", .log, d.createdAt, d.notes),
                item("outcome", .outcome, d.resolvedDate ?? d.createdAt, d.reflection)].compactMap { $0 }
            values += d.revisits.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }.enumerated().compactMap { index,revisit in
                item("revisit\(index + 1)", .revisit, revisit.date, "\(revisit.outcome.shortLabel): \(revisit.note ?? "")", revisitID: revisit.id, containsWrittenNote: revisit.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            }
            return values
        }
    }

    var prompt: String {
        evidence.map { "[\($0.key)] \($0.stage.rawValue) \($0.date.ISO8601Format()): \($0.text)" }.joined(separator: "\n")
    }
    var scope: String { "Read \(decisions.count) of \(eligibleDecisionIDs.count) marked decisions. \(omittedCount) omitted from this reading." }

    func validate() throws {
        guard Set(decisions.map(\.id)).count == decisions.count,
              Set(eligibleDecisionIDs).count == eligibleDecisionIDs.count,
              Set(decisions.map(\.id)).isSubset(of: Set(eligibleDecisionIDs)),
              omittedCount == eligibleDecisionIDs.count - decisions.count,
              decisions.allSatisfy({ $0.actual != nil && Set($0.revisits.map(\.id)).count == $0.revisits.count })
        else { throw ReflectionError.failed }
    }
}
