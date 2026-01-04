//
//  Decision.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation

enum DecisionOutcome: String, Codable, CaseIterable, Identifiable {
    case veryBad = "very bad"
    case bad
    case neutral
    case good
    case veryGood = "very good"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .veryBad: return "Very Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .veryGood: return "Very Good"
        }
    }

    var compactLabel: String {
        switch self {
        case .veryBad: return "V. Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .veryGood: return "V. Good"
        }
    }

    /// Numeric value for weighted calculations (-2 to +2)
    var numericValue: Int {
        switch self {
        case .veryBad: return -2
        case .bad: return -1
        case .neutral: return 0
        case .good: return 1
        case .veryGood: return 2
        }
    }

    /// Whether this is a positive outcome
    var isPositive: Bool {
        self == .good || self == .veryGood
    }

    /// Whether this is a negative outcome
    var isNegative: Bool {
        self == .bad || self == .veryBad
    }
}

enum DecisionCategory: String, Codable, CaseIterable, Identifiable {
    case work
    case money
    case health
    case relationships
    case home
    case other

    var id: String { rawValue }
}

enum DecisionStakes: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    /// Weight multiplier for accuracy calculations
    var weight: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        }
    }
}

struct Decision: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var category: DecisionCategory
    var stakes: DecisionStakes
    var expected: DecisionOutcome
    var actual: DecisionOutcome?
    var notes: String?
    var reflection: String?
    var createdAt: Date
    var followUpDate: Date
    var secondaryFollowUpDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        category: DecisionCategory,
        stakes: DecisionStakes = .medium,
        expected: DecisionOutcome,
        actual: DecisionOutcome? = nil,
        notes: String? = nil,
        reflection: String? = nil,
        createdAt: Date = Date(),
        followUpDate: Date,
        secondaryFollowUpDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.stakes = stakes
        self.expected = expected
        self.actual = actual
        self.notes = notes
        self.reflection = reflection
        self.createdAt = createdAt
        self.followUpDate = followUpDate
        self.secondaryFollowUpDate = secondaryFollowUpDate
    }
}
