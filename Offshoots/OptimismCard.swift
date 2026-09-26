//
//  OptimismCard.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 9/25/26.
//

internal import SwiftUI

struct OptimismCard: View {
    let bias: OptimismBias?
    /// Marked decisions so far, for the progress text before the card unlocks
    let markedCount: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Optimism", systemImage: "sun.max.fill")

            if let bias {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout(spacing: 12))
                layout {
                    Image(systemName: icon(for: bias.lean))
                        .font(.title)
                        .foregroundStyle(color(for: bias.lean))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title(for: bias.lean))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(color(for: bias.lean))
                        Text(detail(for: bias))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                let remaining = AnalyticsEngine.minimumBiasSample - markedCount
                Text("\(markedCount) of \(AnalyticsEngine.minimumBiasSample) marked. Mark \(remaining) more to see whether you tend to expect too much or too little.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func title(for lean: OptimismBias.Lean) -> String {
        switch lean {
        case .optimistic: return "Optimistic"
        case .calibrated: return "Well calibrated"
        case .pessimistic: return "Pessimistic"
        }
    }

    private func icon(for lean: OptimismBias.Lean) -> String {
        switch lean {
        case .optimistic: return "arrow.up.right.circle.fill"
        case .calibrated: return "scope"
        case .pessimistic: return "arrow.down.right.circle.fill"
        }
    }

    private func color(for lean: OptimismBias.Lean) -> Color {
        switch lean {
        case .optimistic: return .offshootPrimary
        case .calibrated: return .outcomeGood
        case .pessimistic: return .offshootPrimary
        }
    }

    private func detail(for bias: OptimismBias) -> String {
        let steps = abs(bias.averageGap).formatted(.number.precision(.fractionLength(1)))
        switch bias.lean {
        case .optimistic:
            return "Your predictions run \(steps) steps better than the first result, across \(bias.sample) decisions."
        case .pessimistic:
            return "Your predictions run \(steps) steps worse than the first result, across \(bias.sample) decisions."
        case .calibrated:
            return "Your predictions match the first result on average, across \(bias.sample) decisions."
        }
    }
}
