//
//  DecisionSpotlightIndexer.swift
//  Offshoots
//

import AppIntents
import CoreSpotlight
import Foundation

/// The Spotlight operations the indexer needs; a protocol so tests can record them
protocol DecisionSearchIndexing {
    func index(_ entities: [DecisionEntity]) async throws
    func delete(ids: [UUID]) async throws
    func deleteAll() async throws
}

/// The real Spotlight index. `CSSearchableIndex` is not Sendable, so each call
/// takes a fresh reference instead of holding one across actors.
struct SpotlightIndex: DecisionSearchIndexing {
    func index(_ entities: [DecisionEntity]) async throws {
        try await CSSearchableIndex.default().indexAppEntities(entities)
    }

    func delete(ids: [UUID]) async throws {
        try await CSSearchableIndex.default().deleteAppEntities(identifiedBy: ids, ofType: DecisionEntity.self)
    }

    func deleteAll() async throws {
        try await CSSearchableIndex.default().deleteAppEntities(ofType: DecisionEntity.self)
    }
}

/// Keeps Spotlight in step with `DecisionStore`. Only `DecisionEntity` values are
/// indexed, so notes and Hindsight answers never reach Spotlight.
final class DecisionSpotlightIndexer {
    private let index: any DecisionSearchIndexing
    private let now: () -> Date
    /// Operations run one after another, in the order the store reported them
    private var tail: Task<Void, Never>?

    init(index: any DecisionSearchIndexing = SpotlightIndex(), now: @escaping () -> Date = { .now }) {
        self.index = index
        self.now = now
    }

    func handle(_ change: DecisionStoreChange, decisions: [Decision]) {
        switch change {
        case .upserted(let ids):
            let wanted = Set(ids)
            let entities = entities(decisions.filter { wanted.contains($0.id) })
            enqueue { index in try await index.index(entities) }
        case .deleted(let ids):
            enqueue { index in try await index.delete(ids: ids) }
        case .replacedAll:
            let entities = entities(decisions)
            enqueue { index in
                try await index.deleteAll()
                if !entities.isEmpty { try await index.index(entities) }
            }
        }
    }

    /// Replaces the whole index with the journal: makes an existing journal
    /// searchable after updating, and removes titles of decisions that are no
    /// longer there. Does nothing while a restore needs recovery.
    func syncAll(decisions: [Decision], blocked: Bool) {
        guard !blocked else { return }
        handle(.replacedAll, decisions: decisions)
    }

    /// Waits for queued operations. Tests use it before reading what was indexed.
    func drain() async {
        await tail?.value
    }

    private func entities(_ decisions: [Decision]) -> [DecisionEntity] {
        let current = now()
        return decisions.map { DecisionEntity($0, now: current) }
    }

    private func enqueue(_ operation: @escaping (any DecisionSearchIndexing) async throws -> Void) {
        let previous = tail
        let index = index
        tail = Task {
            await previous?.value
            do { try await operation(index) }
            catch { print("[DecisionSpotlightIndexer] ❌ Spotlight update failed:", error) }
        }
    }
}
