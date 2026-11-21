//
//  RevisitsLockScreenViews.swift
//  OffshootsWidgets
//

import SwiftUI
import WidgetKit

struct RevisitsLockScreenView: View {
    let entry: RevisitsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let due = entry.summary.due(asOf: entry.date)
        let next = entry.summary.upcoming(asOf: entry.date).first

        Group {
            switch family {
            case .accessoryCircular:
                circularView(dueCount: due.count)
            case .accessoryInline:
                inlineView(dueCount: due.count, next: next)
            case .accessoryRectangular:
                rectangularView(due: due, next: next)
            default:
                circularView(dueCount: due.count)
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private func circularView(dueCount: Int) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            if dueCount == 0 {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.semibold))
                    .accessibilityLabel("Nothing ready to review")
            } else {
                VStack(spacing: 1) {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption2)
                        .widgetAccentable()
                    Text("\(dueCount)")
                        .font(.title3.bold().monospacedDigit())
                        .minimumScaleFactor(0.6)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(dueCount) ready to review")
            }
        }
        .widgetURL(AppRoute.readyToReview.url)
    }

    private func inlineView(dueCount: Int, next: WidgetSummary.Item?) -> some View {
        let label = LockScreenPresentation.inlineLabel(
            dueCount: dueCount,
            nextDueDate: next?.dueDate,
            now: entry.date
        )
        return Label(label.text, systemImage: label.systemImage)
            .widgetURL(AppRoute.readyToReview.url)
    }

    private func rectangularView(due: [WidgetSummary.Item], next: WidgetSummary.Item?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Label("Ready to Review", systemImage: "bell.badge.fill")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .widgetAccentable()
                Spacer(minLength: 4)
                if !due.isEmpty {
                    Text("\(due.count)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                }
            }

            if let first = due.first {
                Text(first.title)
                    .font(.subheadline)
                    .lineLimit(due.count == 1 ? 2 : 1)
                    .privacySensitive()
                if due.count > 1 {
                    Text("+ \(due.count - 1) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("Nothing due today")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(LockScreenPresentation.rectangularEmptySubtitle(nextDueDate: next?.dueDate, now: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(LockScreenPresentation.rectangularRoute(due: due).url)
    }
}
