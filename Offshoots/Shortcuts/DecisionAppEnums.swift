//
//  DecisionAppEnums.swift
//  Offshoots
//

import AppIntents

// Wrappers keep `Decision.swift` free of App Intents. Raw values equal the model's
// raw values: saved shortcuts and donations store them, so never rename a case's
// raw value, only add new cases.

extension AppEnum {
    /// The case's display name, for dialogs and subtitles
    nonisolated var label: String { String(localized: Self.caseDisplayRepresentations[self]!.title) }
}

enum DecisionOutcomeAppEnum: String, AppEnum {
    case veryBad = "very bad"
    case bad
    case neutral
    case good
    case veryGood = "very good"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Outcome"
    static let caseDisplayRepresentations: [DecisionOutcomeAppEnum: DisplayRepresentation] = [
        .veryBad: "Very Bad",
        .bad: "Bad",
        .neutral: "Neutral",
        .good: "Good",
        .veryGood: "Great",
    ]

    init(_ model: DecisionOutcome) { self = Self(rawValue: model.rawValue)! }
    var model: DecisionOutcome { DecisionOutcome(rawValue: rawValue)! }
}

enum DecisionCategoryAppEnum: String, AppEnum {
    case work
    case money
    case health
    case relationships
    case home
    case other

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let caseDisplayRepresentations: [DecisionCategoryAppEnum: DisplayRepresentation] = [
        .work: "Work",
        .money: "Money",
        .health: "Health",
        .relationships: "Relationships",
        .home: "Home",
        .other: "Other",
    ]

    init(_ model: DecisionCategory) { self = Self(rawValue: model.rawValue)! }
    var model: DecisionCategory { DecisionCategory(rawValue: rawValue)! }
}

enum DecisionStakesAppEnum: String, AppEnum {
    case low
    case medium
    case high

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Stakes"
    static let caseDisplayRepresentations: [DecisionStakesAppEnum: DisplayRepresentation] = [
        .low: "Low",
        .medium: "Medium",
        .high: "High",
    ]

    init(_ model: DecisionStakes) { self = Self(rawValue: model.rawValue)! }
    var model: DecisionStakes { DecisionStakes(rawValue: rawValue)! }
}
