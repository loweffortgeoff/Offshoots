//
//  DecisionEntity.swift
//  Offshoots
//

import AppIntents
import CoreSpotlight
import Foundation

/// A decision as Siri, Shortcuts and Spotlight see it. Notes, reflection, revisit
/// notes and Hindsight answers are deliberately absent: only `@Property` members
/// are visible to the system, and none of them carry private text.
struct DecisionEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Decision"),
        numericFormat: "\(placeholder: .int) decisions"
    )
    static let defaultQuery = DecisionEntityQuery()
    /// Listed under NSUserActivityTypes in Info.plist
    static let viewingActivityType = "com.geoffrey.silva.Offshoots.decision"

    /// `Decision.id`: stable across launches, and stored by saved shortcuts
    let id: UUID
    @Property(title: "Title", indexingKey: \.title) var title: String
    @Property(title: "Category") var category: DecisionCategoryAppEnum
    @Property(title: "Stakes") var stakes: DecisionStakesAppEnum
    @Property(title: "Expected Outcome") var expected: DecisionOutcomeAppEnum
    @Property(title: "Current Outcome") var currentOutcome: DecisionOutcomeAppEnum?
    @Property(title: "Next Review Date") var nextReviewDate: Date?
    @Property(title: "Ready to Review") var isReadyForReview: Bool

    @MainActor
    init(_ decision: Decision, now: Date) {
        id = decision.id
        title = decision.title
        category = DecisionCategoryAppEnum(decision.category)
        stakes = DecisionStakesAppEnum(decision.stakes)
        expected = DecisionOutcomeAppEnum(decision.expected)
        currentOutcome = decision.currentOutcome.map(DecisionOutcomeAppEnum.init)
        nextReviewDate = decision.nextReviewDate
        isReadyForReview = decision.isReadyForReview(asOf: now)
    }

    /// Spotlight stores this text when it indexes, so it holds nothing that
    /// changes with the clock (no "Ready to review").
    var displayRepresentation: DisplayRepresentation {
        let subtitle: LocalizedStringResource = if let currentOutcome {
            "\(category.label) · \(currentOutcome.label)"
        } else {
            "\(category.label) · Expected \(expected.label)"
        }
        return DisplayRepresentation(title: "\(title)", subtitle: subtitle)
    }
}

struct DecisionEntityQuery: EntityStringQuery {
    static let suggestionLimit = 10

    @Dependency var service: ShortcutsService

    func entities(for identifiers: [UUID]) async throws -> [DecisionEntity] {
        await MainActor.run {
            let wanted = Set(identifiers)
            let now = Date.now
            return service.decisions.filter { wanted.contains($0.id) }.map { DecisionEntity($0, now: now) }
        }
    }

    func entities(matching string: String) async throws -> [DecisionEntity] {
        await MainActor.run {
            let now = Date.now
            return Self.matches(service.decisions, string: string).map { DecisionEntity($0, now: now) }
        }
    }

    func suggestedEntities() async throws -> [DecisionEntity] {
        await MainActor.run {
            let now = Date.now
            return Self.suggestions(from: service.decisions, now: now).map { DecisionEntity($0, now: now) }
        }
    }

    /// Ready to review (soonest first), then pending decisions not yet due (newest first)
    /// Shared by `suggestedEntities()`; static and pure so tests need no dependency
    @MainActor
    static func suggestions(from decisions: [Decision], now: Date) -> [Decision] {
        let due = decisions
            .filter { $0.isReadyForReview(asOf: now) }
            .sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
        let waiting = decisions
            .filter { $0.actual == nil && !$0.isReadyForReview(asOf: now) }
            .sorted { $0.createdAt > $1.createdAt }
        return Array((due + waiting).prefix(suggestionLimit))
    }

    /// The framework does not filter for us: match title or category name,
    /// ignoring case and accents
    @MainActor
    static func matches(_ decisions: [Decision], string: String) -> [Decision] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return decisions.filter {
            $0.title.range(of: query, options: options) != nil
                || DecisionCategoryAppEnum($0.category).label.range(of: query, options: options) != nil
        }
    }
}

/// iOS 27 lets the system ask for a Spotlight reindex. Earlier versions rely on
/// the store's change hook and the once-per-launch sync in `OffshootsApp`.
@available(iOS 27.0, *)
extension DecisionEntityQuery: IndexedEntityQuery {
    // Both go through the indexer's ordered queue (via the service), so a store
    // change made while Spotlight works is applied after, never undone
    func reindexEntities(for identifiers: [UUID], indexDescription: CSSearchableIndexDescription) async throws {
        await service.reindexSpotlight(ids: identifiers)
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        await service.reindexSpotlight(ids: nil)
    }
}
