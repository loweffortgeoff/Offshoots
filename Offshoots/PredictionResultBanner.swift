//
//  PredictionResultBanner.swift
//  Offshoots
//

internal import SwiftUI

/// How the first rating compared with the prediction, and what unlocks next
struct PredictionResultBanner: View {
    /// First rating minus expected, in steps
    let gap: Int
    /// Marked decisions across the whole store, this one included
    let markedCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                    .foregroundStyle(gap == 0 ? Color.yellow : Color.offshootPrimary)
                Text(Self.message(for: gap))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.offshootPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let unlock = Self.unlockText(markedCount: markedCount) {
                Text(unlock)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(gap == 0 ? Color.yellow.opacity(0.1) : Color.offshootBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        if gap == 0 { return "trophy.fill" }
        return gap > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    static func message(for gap: Int) -> String {
        switch gap {
        case 0: return "You predicted correctly!"
        case 1: return "Close. It went a little better than you expected."
        case -1: return "Close. It went a little worse than you expected."
        case let steps where steps > 1: return "It went better than you expected."
        default: return "It went worse than you expected."
        }
    }

    static func unlockText(markedCount: Int) -> String? {
        if markedCount < AnalyticsEngine.minimumBiasSample {
            return "\(markedCount) of \(AnalyticsEngine.minimumBiasSample) marked · Optimism unlocks at \(AnalyticsEngine.minimumBiasSample)"
        }
        if markedCount < AnalyticsEngine.minimumSoFarSample {
            return "\(markedCount) of \(AnalyticsEngine.minimumSoFarSample) marked · Trend unlocks at \(AnalyticsEngine.minimumSoFarSample)"
        }
        return nil
    }
}

#Preview {
    VStack {
        PredictionResultBanner(gap: 0, markedCount: 1)
        PredictionResultBanner(gap: 1, markedCount: 4)
        PredictionResultBanner(gap: -3, markedCount: 8)
    }
    .padding()
}
