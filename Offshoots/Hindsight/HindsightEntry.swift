import Foundation

struct HindsightEntry: Identifiable, Equatable {
    let decisionID: UUID
    let revisitID: UUID?
    let title: String
    let date: Date
    let answer: HindsightAnswer
    let outcome: DecisionOutcome
    let note: String?
    var id: UUID { decisionID }
}
