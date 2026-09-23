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
        case .veryGood: return "Great"
        }
    }

    var compactLabel: String {
        switch self {
        case .veryBad: return "Very Bad"
        case .bad: return "Bad"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .veryGood: return "Great"
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

/// A later re-rating of a decision after its outcome was first marked
struct Revisit: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    var outcome: DecisionOutcome
    var note: String?

    init(id: UUID = UUID(), date: Date = Date(), outcome: DecisionOutcome, note: String? = nil) {
        self.id = id
        self.date = date
        self.outcome = outcome
        self.note = note
    }
}

struct Decision: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var category: DecisionCategory
    var stakes: DecisionStakes
    var expected: DecisionOutcome
    /// The outcome as first marked; prediction accuracy is measured against this
    var actual: DecisionOutcome?
    var notes: String?
    var reflection: String?
    var createdAt: Date
    var resolvedAt: Date?
    var followUpDate: Date
    /// Next scheduled revisit once an outcome is marked
    var secondaryFollowUpDate: Date?
    /// Re-ratings after the first outcome, oldest first
    var revisits: [Revisit]

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
        resolvedAt: Date? = nil,
        followUpDate: Date,
        secondaryFollowUpDate: Date? = nil,
        revisits: [Revisit] = []
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
        self.resolvedAt = resolvedAt
        self.followUpDate = followUpDate
        self.secondaryFollowUpDate = secondaryFollowUpDate
        self.revisits = revisits
    }

    // Custom decoding so files saved before `revisits` existed still load
    private enum CodingKeys: String, CodingKey {
        case id, title, category, stakes, expected, actual, notes, reflection
        case createdAt, resolvedAt, followUpDate, secondaryFollowUpDate, revisits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(DecisionCategory.self, forKey: .category)
        stakes = try container.decodeIfPresent(DecisionStakes.self, forKey: .stakes) ?? .medium
        expected = try container.decode(DecisionOutcome.self, forKey: .expected)
        actual = try container.decodeIfPresent(DecisionOutcome.self, forKey: .actual)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reflection = try container.decodeIfPresent(String.self, forKey: .reflection)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        resolvedAt = try container.decodeIfPresent(Date.self, forKey: .resolvedAt)
        followUpDate = try container.decode(Date.self, forKey: .followUpDate)
        secondaryFollowUpDate = try container.decodeIfPresent(Date.self, forKey: .secondaryFollowUpDate)
        revisits = try container.decodeIfPresent([Revisit].self, forKey: .revisits) ?? []
    }
}

extension Decision {
    /// Latest assessment: the most recent revisit, else the first marked outcome
    var currentOutcome: DecisionOutcome? {
        revisits.last?.outcome ?? actual
    }

    /// When this decision next needs attention: the review date while pending,
    /// then the next revisit date once an outcome is marked
    var nextReviewDate: Date? {
        actual == nil ? followUpDate : secondaryFollowUpDate
    }

    /// Its review or revisit day has arrived (dates are day-granular in the UI)
    var isReadyForReview: Bool {
        guard let nextReviewDate else { return false }
        return Calendar.current.startOfDay(for: nextReviewDate) <= Date()
    }
}
