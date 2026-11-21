//
//  RevisitsProvider.swift
//  OffshootsWidgets
//

import Foundation
import WidgetKit

nonisolated struct RevisitsEntry: TimelineEntry {
    let date: Date
    let summary: WidgetSummary
}

/// Reads only the summary the app writes. The gallery and placeholder use sample data, never the journal.
nonisolated struct RevisitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RevisitsEntry {
        RevisitsEntry(date: .now, summary: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (RevisitsEntry) -> Void) {
        completion(RevisitsEntry(date: .now, summary: context.isPreview ? .sample : Self.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RevisitsEntry>) -> Void) {
        let now = Date.now
        let summary = Self.load()
        let refreshes = summary.refreshDates(after: now)
        let entries = [RevisitsEntry(date: now, summary: summary)]
            + refreshes.map { RevisitsEntry(date: $0, summary: summary) }
        completion(Timeline(entries: entries, policy: refreshes.last.map { .after($0) } ?? .atEnd))
    }

    static func load() -> WidgetSummary {
        WidgetSummary.containerFileURL
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap(WidgetSummary.decode) ?? .empty
    }
}

extension WidgetSummary {
    /// Widget gallery sample. Made up, so the gallery never shows a real decision.
    nonisolated static let sample: WidgetSummary = {
        let now = Date.now
        return WidgetSummary(version: currentVersion, hindsightOwned: false, items: [
            Item(id: UUID(), title: "Take the Denver job", dueDate: now.addingTimeInterval(-86_400)),
            Item(id: UUID(), title: "Refinance the car", dueDate: now),
            Item(id: UUID(), title: "Join the running club", dueDate: now.addingTimeInterval(3 * 86_400)),
        ])
    }()
}
