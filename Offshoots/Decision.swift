//
//  Decision.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation

enum DecisionOutcome: String, Codable, CaseIterable, Identifiable {
    case good
    case neutral
    case bad

    var id: String { rawValue }
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

struct Decision: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var category: DecisionCategory
    var expected: DecisionOutcome
    var actual: DecisionOutcome?
    var notes: String?
    var reflection: String?
    var createdAt: Date
    var followUpDate: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: DecisionCategory,
        expected: DecisionOutcome,
        actual: DecisionOutcome? = nil,
        notes: String? = nil,
        reflection: String? = nil,
        createdAt: Date = Date(),
        followUpDate: Date
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.expected = expected
        self.actual = actual
        self.notes = notes
        self.reflection = reflection
        self.createdAt = createdAt
        self.followUpDate = followUpDate
    }
}
