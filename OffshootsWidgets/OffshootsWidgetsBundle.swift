//
//  OffshootsWidgetsBundle.swift
//  OffshootsWidgets
//

import SwiftUI
import WidgetKit

@main
struct OffshootsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RevisitsMediumWidget()
        RevisitsSmallWidget()
        RevisitsLockScreenWidget()
        LogDecisionControl()
    }
}

struct RevisitsLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RevisitsLockScreen", provider: RevisitsProvider()) { entry in
            RevisitsLockScreenView(entry: entry)
        }
        .configurationDisplayName("Ready to Review")
        .description("See decisions ready to review on your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct RevisitsMediumWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RevisitsMedium", provider: RevisitsProvider()) { entry in
            RevisitsMediumView(entry: entry)
        }
        .configurationDisplayName("Review and Log")
        .description("Decisions ready to review, with quick links to log one or open Hindsight.")
        .supportedFamilies([.systemMedium])
    }
}

struct RevisitsSmallWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RevisitsSmall", provider: RevisitsProvider()) { entry in
            RevisitsSmallView(entry: entry)
        }
        .configurationDisplayName("Ready to Review")
        .description("How many decisions are ready to review.")
        .supportedFamilies([.systemSmall])
    }
}
