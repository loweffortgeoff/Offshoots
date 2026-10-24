import Foundation

struct ReflectionFreshness: Equatable {
    let changed: Set<UUID>
    let missing: Set<UUID>
    let added: Set<UUID>
    var needsRefresh: Bool { !changed.isEmpty || !missing.isEmpty || !added.isEmpty }

    static func status(for reading: SavedReflection, decisions: [Decision]) -> Self {
        let normalized = (try? DecisionStore.decode(DecisionStore.encode(decisions))) ?? decisions
        let current = Dictionary(normalized.map { ($0.id,$0) }, uniquingKeysWith: { first,_ in first })
        let sources = reading.snapshot.decisions
        let changed = Set(sources.filter { current[$0.id] != nil && current[$0.id] != $0 }.map(\.id))
        let missing = Set(sources.filter { current[$0.id] == nil }.map(\.id))
        let eligible = Set(decisions.filter { $0.actual != nil }.map(\.id))
        let added = reading.kind == .patterns ? eligible.subtracting(reading.snapshot.eligibleDecisionIDs) : []
        return Self(changed: changed, missing: missing, added: added)
    }
}
