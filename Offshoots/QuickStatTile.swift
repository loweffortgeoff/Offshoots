//
//  QuickStatTile.swift
//  Offshoots
//

internal import SwiftUI

/// One tile in the dashboard's Quick Stats row.
struct QuickStatTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var valueColor: Color = .primary
    /// What VoiceOver reads for the title, when the printed title has symbols
    var spokenTitle: String? = nil

    /// Symbols differ in height; a shared row height keeps the text lines aligned.
    @ScaledMetric(relativeTo: .callout) private var iconRowHeight: CGFloat = 22

    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(iconColor)
                    .frame(height: iconRowHeight)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(spokenTitle ?? title)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(valueColor)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .combine)
    }
}
