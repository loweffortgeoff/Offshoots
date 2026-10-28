import Foundation

/// Exact records selected for one request. Never truncates a note to fit a prompt.
struct ReflectionSourceSnapshot: Codable, Equatable {
    let decisions: [Decision]
    let eligibleDecisionIDs: [UUID]
    let subjectID: UUID?
    let omittedCount: Int

    /// Conservative UTF-8 bound for systems without the token-count API (before iOS 26.4).
    /// `LiveReflectionService.snapshot(for:decisions:)` fills a token budget instead.
    static let byteBudget = 1800

    static func capture(decisions: [Decision], subjectID: UUID?) -> Self {
        let (eligible, candidates) = ordered(decisions, subjectID: subjectID)
        var kept: [Decision] = []
        for decision in candidates {
            let candidate = Self(decisions: kept + [decision], eligibleDecisionIDs: [], subjectID: subjectID, omittedCount: 0)
            if candidate.prompt.utf8.count <= byteBudget { kept.append(decision) }
        }
        return selection(kept: kept, eligible: eligible, subjectID: subjectID)
    }

    /// Same selection, but `fits` decides each candidate, so a caller can count real tokens.
    /// A record that does not fit is skipped whole, and smaller later records are still tried.
    static func capture(decisions: [Decision], subjectID: UUID?, fits: (Self) async throws -> Bool) async rethrows -> Self {
        let (eligible, candidates) = ordered(decisions, subjectID: subjectID)
        var kept: [Decision] = []
        for decision in candidates {
            let candidate = Self(decisions: kept + [decision], eligibleDecisionIDs: [], subjectID: subjectID, omittedCount: 0)
            if try await fits(candidate) { kept.append(decision) }
        }
        return selection(kept: kept, eligible: eligible, subjectID: subjectID)
    }

    private static func selection(kept: [Decision], eligible: [Decision], subjectID: UUID?) -> Self {
        Self(decisions: kept, eligibleDecisionIDs: eligible.map(\.id).sorted { $0.uuidString < $1.uuidString },
             subjectID: subjectID, omittedCount: eligible.count - kept.count)
    }

    /// Marked decisions newest first with the subject on top, and the ones a prompt may read:
    /// a record with instruction-like text is left out whole.
    private static func ordered(_ decisions: [Decision], subjectID: UUID?) -> (eligible: [Decision], candidates: [Decision]) {
        let normalized = (try? DecisionStore.decode(DecisionStore.encode(decisions))) ?? decisions
        var seen = Set<UUID>()
        let eligible = normalized.filter { $0.actual != nil && seen.insert($0.id).inserted }
            .sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt > $1.createdAt }
        let ordered = eligible.sorted { a,b in
            if a.id == subjectID { return b.id != subjectID }
            if b.id == subjectID { return false }
            return a.createdAt == b.createdAt ? a.id.uuidString < b.id.uuidString : a.createdAt > b.createdAt
        }
        let candidates = ordered.filter { decision in
            let written = [decision.title, decision.notes, decision.reflection] + decision.revisits.map(\.note)
            return !written.compactMap({ $0 }).contains(where: ReflectionText.looksLikeModelInstruction)
        }
        return (eligible, candidates)
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

    /// What the model reads. Same keys as `evidence`, but compact: day numbers from the log date
    /// instead of timestamps, and the stakes and hindsight answers the evidence text leaves out.
    var prompt: String {
        let byID = Dictionary(decisions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return evidence.compactMap { item -> String? in
            guard let d = byID[item.decisionID] else { return nil }
            let day = "day \(Self.days(from: d.createdAt, to: item.date))"
            switch item.stage {
            case .record:
                return "[\(item.key)] " + Self.recordLine(d)
            case .log, .outcome:
                return "[\(item.key)] \(item.stage.rawValue) \(day): \(item.text)"
            case .revisit:
                let revisit = d.revisits.first { $0.id == item.revisitID }
                var line = "[\(item.key)] revisit \(day), rated \(revisit?.outcome.shortLabel ?? "")"
                if let hindsight = revisit?.hindsight { line += ", hindsight \(hindsight.label)" }
                if let note = revisit?.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty { line += ": " + note }
                return line
            }
        }.joined(separator: "\n")
    }

    private static func recordLine(_ d: Decision) -> String {
        var line = "\(d.title) | \(d.category.rawValue), \(d.stakes.rawValue) stakes | logged \(d.createdAt.formatted(.iso8601.year().month().day()))"
        line += " | expected \(d.expected.shortLabel), first \(d.actual?.shortLabel ?? "unmarked")"
        if let resolved = d.resolvedDate { line += " on day \(days(from: d.createdAt, to: resolved))" }
        if let hindsight = d.hindsight { line += " | hindsight \(hindsight.label)" }
        return line
    }

    /// Whole days, never negative. Fixed 24-hour days so the prompt does not depend on the time zone.
    private static func days(from start: Date, to end: Date) -> Int {
        max(0, Int(end.timeIntervalSince(start) / 86_400))
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
