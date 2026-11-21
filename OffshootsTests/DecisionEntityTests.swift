//
//  DecisionEntityTests.swift
//  OffshootsTests
//

import AppIntents
import Foundation
import Testing
@testable import Offshoots

@MainActor
@Suite struct DecisionEntityTests {
    let now = Make.day(26)

    private func pending(_ title: String, category: DecisionCategory = .work,
                         due: Date, created: Date = Make.day(0)) -> Decision {
        Decision(title: title, category: category, expected: .good, createdAt: created, followUpDate: due)
    }

    private func subtitle(_ entity: DecisionEntity) -> String? {
        entity.displayRepresentation.subtitle.map { String(localized: $0) }
    }

    @Test func enumRawValuesMatchModel() {
        for outcome in DecisionOutcome.allCases {
            #expect(DecisionOutcomeAppEnum(outcome).rawValue == outcome.rawValue)
            #expect(DecisionOutcomeAppEnum(outcome).model == outcome)
        }
        for category in DecisionCategory.allCases {
            #expect(DecisionCategoryAppEnum(category).rawValue == category.rawValue)
            #expect(DecisionCategoryAppEnum(category).model == category)
        }
        for stakes in DecisionStakes.allCases {
            #expect(DecisionStakesAppEnum(stakes).rawValue == stakes.rawValue)
            #expect(DecisionStakesAppEnum(stakes).model == stakes)
        }
        #expect(DecisionOutcomeAppEnum.caseDisplayRepresentations.count == DecisionOutcome.allCases.count)
        #expect(DecisionCategoryAppEnum.caseDisplayRepresentations.count == 6)
        #expect(DecisionStakesAppEnum.caseDisplayRepresentations.count == 3)
        #expect(String(localized: DecisionOutcomeAppEnum.caseDisplayRepresentations[.veryGood]!.title) == "Great")
    }

    @Test func entityMapsFieldsAndHidesPrivateText() {
        var decision = Decision(title: "Take the job", category: .money, stakes: .high, expected: .good,
                                actual: .good, notes: "secret note", reflection: "secret reflection",
                                createdAt: Make.day(0), resolvedAt: Make.day(7), followUpDate: Make.day(7),
                                secondaryFollowUpDate: Make.day(30),
                                revisits: [Revisit(outcome: .bad, note: "secret revisit")])
        decision.hindsight = nil
        let entity = DecisionEntity(decision, now: now)

        #expect(entity.id == decision.id)
        #expect(entity.title == "Take the job")
        #expect(entity.category == .money)
        #expect(entity.stakes == .high)
        #expect(entity.expected == .good)
        #expect(entity.currentOutcome == .bad)
        #expect(entity.nextReviewDate == Make.day(30))
        #expect(entity.isReadyForReview == false)

        let visible = [String(localized: entity.displayRepresentation.title), subtitle(entity) ?? ""]
            + Mirror(reflecting: entity).children.map { String(describing: $0.value) }
        #expect(!visible.joined().contains("secret"))
    }

    @Test func subtitleNeverSaysReadyToReview() {
        let due = DecisionEntity(pending("Due", due: Make.day(20)), now: now)
        #expect(due.isReadyForReview)
        #expect(subtitle(due) == "Work · Expected Good")

        let marked = DecisionEntity(Make.marked(.good, .veryGood), now: now)
        #expect(subtitle(marked) == "Work · Great")
    }

    @Test func suggestionsPutDueFirstAndCapAtTen() {
        let due = [pending("due 24", due: Make.day(24)), pending("due 20", due: Make.day(20)),
                   pending("due 26", due: now)]
        let waiting = (0..<12).map { pending("waiting \($0)", due: Make.day(40), created: Make.day($0)) }
        let suggestions = DecisionEntityQuery.suggestions(from: waiting + due, now: now)

        #expect(suggestions.count == 10)
        #expect(suggestions.prefix(3).map(\.title) == ["due 20", "due 24", "due 26"])
        #expect(suggestions[3].title == "waiting 11")
        #expect(Set(suggestions.map(\.id)).count == 10)
    }

    @Test func stringMatchCoversTitleAndCategory() {
        let job = pending("Take the job", due: Make.day(40))
        let car = pending("Sell the car", category: .money, due: Make.day(40))
        let cafe = pending("Open a café", category: .home, due: Make.day(40))
        let all = [job, car, cafe]

        #expect(DecisionEntityQuery.matches(all, string: "JOB").map(\.id) == [job.id])
        #expect(DecisionEntityQuery.matches(all, string: "money").map(\.id) == [car.id])
        #expect(DecisionEntityQuery.matches(all, string: "cafe").map(\.id) == [cafe.id])
        #expect(DecisionEntityQuery.matches(all, string: "  ").isEmpty)
    }
}
