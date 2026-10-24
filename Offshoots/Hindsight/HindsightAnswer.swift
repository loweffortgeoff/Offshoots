import Foundation

enum HindsightAnswer: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case sameApproach, differentApproach, differentChoice, notSure
    var id: Self { self }
    var label: String {
        switch self {
        case .sameApproach: "Same approach"
        case .differentApproach: "Different approach"
        case .differentChoice: "Different choice"
        case .notSure: "Not sure"
        }
    }
    var detail: String {
        switch self {
        case .sameApproach: "I would make this choice and approach it the same way."
        case .differentApproach: "I would keep the underlying choice but change how I carried it out."
        case .differentChoice: "I would choose another course, including not doing it."
        case .notSure: "I have considered it and do not yet know."
        }
    }
}
