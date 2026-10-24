import Foundation

struct HindsightReviewFilter: Equatable {
    var answer: HindsightAnswer?
    var outcome: DecisionOutcome?
    mutating func toggle(_ value: HindsightAnswer) { answer = answer == value ? nil : value }
    func apply(to entries: [HindsightEntry]) -> [HindsightEntry] {
        HindsightSummary.filtered(entries, answer: answer, outcome: outcome)
    }
}
