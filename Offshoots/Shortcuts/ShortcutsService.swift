//
//  ShortcutsService.swift
//  Offshoots
//

import Foundation

/// The one place Siri and Shortcuts read and change decisions. `OffshootsApp.init()`
/// registers the app's single instance with `AppDependencyManager`, so intents that
/// run with no scene mounted share the UI's store and widget writer.
///
/// Every write validates first and changes the store last: an intent's `perform()`
/// can run again from the top, and nothing must be half-written before a refusal.
final class ShortcutsService {
    enum RecordResult: Equatable {
        case firstOutcome(Decision)
        case revisit(Decision)
    }

    private let store: DecisionStore
    private let widgetSummary: WidgetSummaryWriter
    private let spotlight: DecisionSpotlightIndexer?
    private let now: () -> Date
    private let calendar: Calendar

    init(store: DecisionStore, widgetSummary: WidgetSummaryWriter, spotlight: DecisionSpotlightIndexer? = nil,
         now: @escaping () -> Date = { .now }, calendar: Calendar = .current) {
        self.store = store
        self.widgetSummary = widgetSummary
        self.spotlight = spotlight
        self.now = now
        self.calendar = calendar
    }

    /// Answers the system's iOS 27 reindex requests (nil = everything) through the
    /// indexer's ordered queue, so a delete made meanwhile is never undone.
    /// Returns once the queued work is done. Does nothing while blocked.
    func reindexSpotlight(ids: [UUID]?) async {
        guard let spotlight, !isBlocked else { return }
        if let ids {
            spotlight.handle(.upserted(ids), decisions: store.decisions)
        } else {
            spotlight.syncAll(decisions: store.decisions, blocked: isBlocked)
        }
        await spotlight.drain()
    }

    /// True while a restore needs recovery
    var isBlocked: Bool { store.recoveryError != nil }

    var decisions: [Decision] { store.decisions }

    func logDecision(title: String, expected: DecisionOutcome, category: DecisionCategory,
                     stakes: DecisionStakes, reviewDate: Date?, notes: String?) throws -> Decision {
        guard !isBlocked else { throw ShortcutsError.blocked }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw ShortcutsError.blankTitle }

        let current = now()
        let tomorrow = ReviewDatePreset.tomorrow.date(from: current, calendar: calendar)
        let followUpDate = reviewDate ?? tomorrow
        // Same floor as the Log form: a same-day review would be ready at once
        guard followUpDate >= calendar.startOfDay(for: tomorrow) else { throw ShortcutsError.reviewDateTooEarly }

        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let decision = store.createDecision(
            title: trimmedTitle,
            category: category,
            stakes: stakes,
            expected: expected,
            notes: trimmedNotes?.isEmpty == false ? trimmedNotes : nil,
            followUpDate: followUpDate
        )
        refreshWidgets()
        return decision
    }

    func recordOutcome(decisionID: UUID, outcome: DecisionOutcome, note: String?,
                       nextRevisitDate: Date?) throws -> RecordResult {
        guard !isBlocked else { throw ShortcutsError.blocked }
        guard let decision = store.decisions.first(where: { $0.id == decisionID }) else {
            throw ShortcutsError.decisionMissing
        }
        if let nextRevisitDate, nextRevisitDate < calendar.startOfDay(for: now()) {
            throw ShortcutsError.revisitDateInPast
        }

        let isFirstOutcome = decision.actual == nil
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved = if isFirstOutcome {
            store.resolveDecision(id: decisionID, actual: outcome,
                                  reflection: trimmedNote?.isEmpty == false ? trimmedNote : nil,
                                  secondaryFollowUpDate: nextRevisitDate, hindsight: nil)
        } else {
            store.addRevisit(id: decisionID, outcome: outcome, note: trimmedNote,
                             nextRevisitDate: nextRevisitDate, hindsight: nil)
        }
        guard saved, let updated = store.decisions.first(where: { $0.id == decisionID }) else {
            throw ShortcutsError.decisionMissing
        }
        refreshWidgets()
        return isFirstOutcome ? .firstOutcome(updated) : .revisit(updated)
    }

    /// Reviews and revisits whose day has arrived, most overdue first
    func readyForReview(category: DecisionCategory?) -> [Decision] {
        let current = now()
        return store.decisions(in: category)
            .filter { $0.isReadyForReview(asOf: current) }
            .sorted { ($0.nextReviewDate ?? .distantPast) < ($1.nextReviewDate ?? .distantPast) }
    }

    /// The UI refreshes widgets on `store.revision`, but no scene may be mounted
    /// when Siri runs an intent, so the service writes the summary itself.
    private func refreshWidgets() {
        widgetSummary.update(decisions: store.decisions, blocked: isBlocked, now: now())
    }
}
