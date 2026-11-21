//
//  WidgetSummary.swift
//  Shared by the app and the widget extension
//

import Foundation

/// The app's day rule for "due": a review date counts from the start of its day.
nonisolated enum DueDay {
    static func isDue(_ date: Date, asOf now: Date, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: date) <= now
    }
}

/// What the widget may know: titles, IDs and due dates. Never notes, answers or outcomes.
/// The app writes it to the App Group container; the widget only reads it.
nonisolated struct WidgetSummary: Codable, Equatable {
    static let currentVersion = 1
    static let fileName = "widget-summary.json"
    static let appGroup = "group.com.geoffrey.silva.Offshoots"
    static let upcomingLimit = 10

    var version: Int
    var hindsightOwned: Bool
    /// Soonest first
    var items: [Item]

    struct Item: Codable, Equatable, Identifiable {
        var id: UUID
        var title: String
        var dueDate: Date
    }

    static let empty = WidgetSummary(version: currentVersion, hindsightOwned: false, items: [])

    func due(asOf now: Date, calendar: Calendar = .current) -> [Item] {
        items.filter { DueDay.isDue($0.dueDate, asOf: now, calendar: calendar) }
    }

    func upcoming(asOf now: Date, calendar: Calendar = .current) -> [Item] {
        items.filter { !DueDay.isDue($0.dueDate, asOf: now, calendar: calendar) }
    }

    /// The start of each later day on which an upcoming item becomes due, so the widget's count changes at midnight.
    func refreshDates(after now: Date, limit: Int = 5, calendar: Calendar = .current) -> [Date] {
        let days = upcoming(asOf: now, calendar: calendar).map { calendar.startOfDay(for: $0.dueDate) }
        return Array(Array(Set(days)).sorted().prefix(limit))
    }

    static func decode(_ data: Data) -> WidgetSummary? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let summary = try? decoder.decode(WidgetSummary.self, from: data),
              summary.version == currentVersion else { return nil }
        return summary
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    static var containerFileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(fileName)
    }
}
