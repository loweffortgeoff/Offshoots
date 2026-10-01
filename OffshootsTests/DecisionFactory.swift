//
//  DecisionFactory.swift
//  OffshootsTests
//

import Foundation
@testable import Offshoots

/// Small builders so each test states only what it cares about.
@MainActor
enum Make {
    /// Whole days after 2026-09-01 12:00 UTC. Offsets stay inside September so DST never matters.
    static func day(_ offset: Int) -> Date {
        ISO8601DateFormatter().date(from: "2026-09-01T12:00:00Z")!.addingTimeInterval(Double(offset) * 86_400)
    }

    static func decision(
        title: String = "Take the job",
        category: DecisionCategory = .work,
        stakes: DecisionStakes = .medium,
        expected: DecisionOutcome = .good,
        actual: DecisionOutcome? = nil,
        notes: String? = nil,
        reflection: String? = nil,
        createdAt: Date = Make.day(0),
        resolvedAt: Date? = nil,
        revisits: [Revisit] = []
    ) -> Decision {
        Decision(
            title: title,
            category: category,
            stakes: stakes,
            expected: expected,
            actual: actual,
            notes: notes,
            reflection: reflection,
            createdAt: createdAt,
            resolvedAt: resolvedAt,
            followUpDate: Make.day(7),
            revisits: revisits
        )
    }

    /// A marked decision that needs no other detail.
    static func marked(_ expected: DecisionOutcome = .good, _ actual: DecisionOutcome = .good) -> Decision {
        decision(expected: expected, actual: actual, resolvedAt: day(7))
    }
}
