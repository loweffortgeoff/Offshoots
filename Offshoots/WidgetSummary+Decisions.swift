//
//  WidgetSummary+Decisions.swift
//  Offshoots
//

import Foundation

extension WidgetSummary {
    /// Every due decision (so the count stays exact) plus the next `upcomingLimit` upcoming ones.
    init(decisions: [Decision], hindsightOwned: Bool, now: Date, calendar: Calendar = .current) {
        let scheduled = decisions
            .compactMap { d in d.nextReviewDate.map { Item(id: d.id, title: d.title, dueDate: $0) } }
            .sorted { $0.dueDate < $1.dueDate }
        let due = scheduled.filter { DueDay.isDue($0.dueDate, asOf: now, calendar: calendar) }
        let upcoming = scheduled.filter { !DueDay.isDue($0.dueDate, asOf: now, calendar: calendar) }
        self.init(version: Self.currentVersion, hindsightOwned: hindsightOwned,
                  items: due + upcoming.prefix(Self.upcomingLimit))
    }
}
