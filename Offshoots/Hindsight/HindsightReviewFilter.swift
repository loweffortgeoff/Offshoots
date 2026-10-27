import Foundation

struct HindsightReviewFilter: Equatable {
    var answer: HindsightAnswer?
    var outcome: DecisionOutcome?
    var category: DecisionCategory?
    mutating func toggle(_ value: HindsightAnswer) { answer = answer == value ? nil : value }
    func apply(to entries: [HindsightEntry]) -> [HindsightEntry] {
        HindsightSummary.filtered(entries, answer: answer, outcome: outcome, category: category)
    }
}
