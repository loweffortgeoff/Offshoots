//
//  WidgetSummaryWriter.swift
//  Offshoots
//

import Foundation
import WidgetKit

/// Writes `widget-summary.json` to the App Group container and asks WidgetKit to reload.
/// The journal never leaves the app; the widget sees only this summary.
@MainActor
final class WidgetSummaryWriter {
    private let fileURL: URL?
    private let reload: @Sendable () -> Void
    private let queue = DispatchQueue(label: "WidgetSummaryWriter")
    private var items: [WidgetSummary.Item]?
    private var hindsightOwned: Bool
    private var lastWritten: Data?

    /// The owned flag starts from the file already on disk, so a launch where StoreKit has not answered yet keeps the last known value.
    init(fileURL: URL?, reload: @escaping @Sendable () -> Void = { WidgetCenter.shared.reloadAllTimelines() }) {
        self.fileURL = fileURL
        self.reload = reload
        let existing = fileURL.flatMap { try? Data(contentsOf: $0) }.flatMap(WidgetSummary.decode)
        hindsightOwned = existing?.hindsightOwned ?? false
    }

    /// `blocked` is true while a restore needs recovery: the widget keeps the last good summary.
    func update(decisions: [Decision], blocked: Bool, now: Date = .now) {
        guard !blocked else { return }
        items = WidgetSummary(decisions: decisions, hindsightOwned: hindsightOwned, now: now).items
        write()
    }

    /// Call only once ownership has resolved.
    func update(hindsightOwned owned: Bool) {
        hindsightOwned = owned
        // Before the first journal update there is nothing to write yet; the flag rides along with it
        if items != nil { write() }
    }

    /// Blocks until queued writes finish. Tests use it before reading the file back.
    func waitForPendingWrites() {
        queue.sync {}
    }

    private func write() {
        guard let fileURL, let items else { return }
        let summary = WidgetSummary(version: WidgetSummary.currentVersion, hindsightOwned: hindsightOwned, items: items)
        guard let data = try? summary.encoded(), data != lastWritten else { return }
        lastWritten = data
        let reload = reload
        queue.async {
            do {
                try data.write(to: fileURL, options: [.atomic])
                reload()
            } catch {
                print("[WidgetSummaryWriter] ❌ Failed to write summary:", error)
            }
        }
    }
}
