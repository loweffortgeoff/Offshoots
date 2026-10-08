//
//  DecisionsSelection.swift
//  Offshoots
//

/// Which decision the detail pane shows. The path is the one source of truth:
/// the last decision in it is the selected one, if it still exists.
enum DecisionsSelection {
    static func current(path: [Decision], in decisions: [Decision]) -> Decision? {
        guard let last = path.last, decisions.contains(where: { $0.id == last.id }) else {
            return nil
        }
        return last
    }

    /// The path without decisions that no longer exist. Without this, a decision deleted
    /// while the detail pane shows it stays in the path, and the next rotation to one
    /// column pushes a detail page for it.
    static func pruned(path: [Decision], in decisions: [Decision]) -> [Decision] {
        path.filter { entry in decisions.contains { $0.id == entry.id } }
    }
}
