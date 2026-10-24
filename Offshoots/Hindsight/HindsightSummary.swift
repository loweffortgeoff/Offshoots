import Foundation

/// Recorded answers, not an interpretation of outcomes or notes.
enum HindsightSummary {
    static func entries(from decisions: [Decision]) -> [HindsightEntry] {
        decisions.compactMap { decision -> HindsightEntry? in
            guard let firstOutcome = decision.actual, let firstDate = decision.resolvedDate else { return nil }
            if let revisit = decision.revisits.last(where: { $0.hindsight != nil }), let answer = revisit.hindsight {
                return HindsightEntry(decisionID: decision.id, revisitID: revisit.id, title: decision.title,
                    date: revisit.date, answer: answer, outcome: revisit.outcome, note: revisit.note)
            }
            guard let answer = decision.hindsight else { return nil }
            return HindsightEntry(decisionID: decision.id, revisitID: nil, title: decision.title,
                date: firstDate, answer: answer, outcome: firstOutcome, note: decision.reflection)
        }.sorted { $0.date == $1.date ? $0.decisionID.uuidString < $1.decisionID.uuidString : $0.date > $1.date }
    }

    static func count(_ answer: HindsightAnswer, in entries: [HindsightEntry]) -> Int {
        entries.filter { $0.answer == answer }.count
    }

    static func filtered(_ entries: [HindsightEntry], answer: HindsightAnswer?, outcome: DecisionOutcome?) -> [HindsightEntry] {
        entries.filter { (answer == nil || $0.answer == answer) && (outcome == nil || $0.outcome == outcome) }
    }
}
