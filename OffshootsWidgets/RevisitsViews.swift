//
//  RevisitsViews.swift
//  OffshootsWidgets
//

import SwiftUI
import WidgetKit

/// "Next: <title> · Tuesday" within a week, else "Next: <title> · Oct 18"
private func nextLine(_ item: WidgetSummary.Item, now: Date) -> String {
    let soon = item.dueDate.timeIntervalSince(now) < 7 * 86_400
    let day = soon ? item.dueDate.formatted(.dateTime.weekday(.wide)) : item.dueDate.formatted(.dateTime.month().day())
    return "Next: \(item.title) · \(day)"
}

struct RevisitsMediumView: View {
    let entry: RevisitsEntry

    var body: some View {
        let due = entry.summary.due(asOf: entry.date)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Ready to Review", systemImage: "bell.badge.fill")
                    .font(.headline)
                    .foregroundStyle(Color(.accent))
                    .widgetAccentable()
                Spacer()
                Text("\(due.count)")
                    .font(.headline.monospacedDigit())
            }

            if due.isEmpty {
                Text("Nothing to review today")
                    .font(.subheadline.weight(.semibold))
                if let next = entry.summary.upcoming(asOf: entry.date).first {
                    Text(nextLine(next, now: entry.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .privacySensitive()
                } else {
                    Text("Nothing scheduled. Log a decision.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(due.prefix(2)) { item in
                    Link(destination: AppRoute.decision(item.id).url) {
                        HStack {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .privacySensitive()
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Link(destination: AppRoute.log.url) {
                    pill("Log a decision", systemImage: "plus")
                }
                Spacer(minLength: 0)
                Link(destination: AppRoute.hindsight.url) {
                    pill("Hindsight", systemImage: entry.summary.hindsightOwned ? "arrow.uturn.backward" : "lock.fill")
                }
            }
        }
        .widgetURL(AppRoute.readyToReview.url)
        .containerBackground(Color(.widgetBackground), for: .widget)
    }

    @Environment(\.widgetRenderingMode) private var renderingMode

    /// Tinted and clear Home Screens flatten solid colors, so a solid capsule would hide its own label there
    private func pill(_ title: String, systemImage: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage).widgetAccentable()
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(renderingMode == .fullColor ? AnyShapeStyle(Color(.accent)) : AnyShapeStyle(.primary))
        .background {
            if renderingMode == .fullColor {
                Capsule().fill(Color(.offshootCardBackground))
            } else {
                Capsule().fill(.quaternary)
            }
        }
    }
}

struct RevisitsSmallView: View {
    let entry: RevisitsEntry

    var body: some View {
        let due = entry.summary.due(asOf: entry.date)
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "bell.badge.fill")
                .font(.title3)
                .foregroundStyle(Color(.accent))
                .widgetAccentable()
            Spacer(minLength: 0)
            if due.isEmpty {
                Text("Nothing due")
                    .font(.headline)
                if let next = entry.summary.upcoming(asOf: entry.date).first {
                    Text(next.dueDate.formatted(.dateTime.weekday(.abbreviated).month().day()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("\(due.count)")
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.6)
                Text("Ready to Review")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(AppRoute.readyToReview.url)
        .containerBackground(Color(.widgetBackground), for: .widget)
    }
}
