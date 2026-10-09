//
//  UnlockReflectionSheet.swift
//  Offshoots
//

internal import SwiftUI

/// "Unlock Reflection". Shown at the tap on a locked control, never at launch.
/// Layout follows purchase sheet concept A ("Show the output"): a headline, a sample of what
/// Reflection shows, then the list of what it adds.
struct UnlockReflectionSheet: View {
    let purchase: ReflectionPurchase

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("See what your decisions add up to.")
                            .font(.largeTitle.bold())
                        Text("Reflection reads your reviewed decisions and shows where your predictions hold up, and where they don't.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ExampleCard()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reflection adds")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                        FeatureRow(title: "Patterns across all your decisions", systemImage: "chart.line.uptrend.xyaxis")
                        FeatureRow(title: "A reflection on each decision you review", systemImage: "arrow.triangle.2.circlepath")
                        FeatureRow(title: "Clearer notes, only when you tap", systemImage: "doc.text")
                    }

                    // At accessibility sizes the buttons scroll with the content, so they cannot cover it
                    if dynamicTypeSize.isAccessibilitySize {
                        PurchaseControls(purchase: purchase, dismiss: { dismiss() })
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    PurchaseControls(purchase: purchase, dismiss: { dismiss() })
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.offshootBackground)
                }
            }
            .background(Color.offshootBackground)
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await purchase.loadProduct() }
        }
    }
}

/// A fixed sample of the output: eight Work decisions, mostly expected Neutral or worse,
/// mostly turned out Good or Great. Not the user's data.
private struct ExampleCard: View {
    private static let expected: [(outcome: DecisionOutcome, count: Int)] = [
        (.bad, 2), (.neutral, 4), (.good, 2)
    ]
    private static let turnedOut: [(outcome: DecisionOutcome, count: Int)] = [
        (.bad, 1), (.neutral, 2), (.good, 3), (.veryGood, 2)
    ]
    private static let total = 8

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    tag
                    Spacer()
                    context
                }
                VStack(alignment: .leading, spacing: 6) {
                    tag
                    context
                }
            }

            Text("You undersell your Work decisions")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.offshootPrimary)

            Text("You expected Neutral or worse on 6 of 8. Five turned out Good or Great.")
                .font(.body)

            VStack(alignment: .leading, spacing: 10) {
                barRow("Expected", Self.expected)
                barRow("Turned out", Self.turnedOut)
                legend
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Expected: 2 Bad, 4 Neutral, 2 Good. Turned out: 1 Bad, 2 Neutral, 3 Good, 2 Great.")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.secondary.opacity(0.2))
        )
    }

    private var tag: some View {
        Text("Example")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.2), in: Capsule())
    }

    private var context: some View {
        Text("Work · 8 reviewed")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func barRow(_ title: String, _ counts: [(outcome: DecisionOutcome, count: Int)]) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 84, alignment: .leading)
            ExampleBar(counts: counts, total: Self.total)
        }
    }

    private var legend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { legendItems }
            VStack(alignment: .leading, spacing: 4) { legendItems }
        }
    }

    private var legendItems: some View {
        ForEach([DecisionOutcome.bad, .neutral, .good, .veryGood]) { outcome in
            HStack(spacing: 6) {
                Circle()
                    .fill(outcome.themeColor)
                    .frame(width: 8, height: 8)
                Text(outcome.compactLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// One stacked bar, worst outcome on the left. Each segment is its share of the total width.
private struct ExampleBar: View {
    let counts: [(outcome: DecisionOutcome, count: Int)]
    let total: Int

    private let gap: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let usable = proxy.size.width - gap * CGFloat(max(counts.count - 1, 0))
            HStack(spacing: gap) {
                ForEach(counts, id: \.outcome) { item in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.outcome.themeColor)
                        .frame(width: usable * CGFloat(item.count) / CGFloat(max(total, 1)))
                }
            }
        }
        .frame(height: 16)
    }
}

private struct FeatureRow: View {
    let title: String
    let systemImage: String

    @ScaledMetric private var iconWidth = 28.0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.offshootPrimary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

private struct PurchaseControls: View {
    let purchase: ReflectionPurchase
    let dismiss: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 12) {
            switch purchase.state {
            case .loading, .purchasing:
                ProgressView().frame(maxWidth: .infinity)
            case .ready(let displayPrice):
                buyButton("Unlock Reflection • \(displayPrice)")
                Text("One-time purchase. Logging and reviewing stay free.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .pending:
                Text("Your purchase is waiting for approval. Reflection unlocks when it is approved.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .unavailable:
                Text("The App Store is not available right now. Try again later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                buyButton("Try Again")
            }

            Button {
                Task { await purchase.restore() }
            } label: {
                // Full width at accessibility sizes, so the wrapped text does not touch the pill's edges
                Text("Restore Purchase")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
            }
            .buttonStyle(.borderless)
            .tint(Color.offshootPrimary)
            .disabled(purchase.isRestoring)
            if let message = purchase.restoreMessage {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func buyButton(_ title: String) -> some View {
        Button {
            Task { if await purchase.buy() { dismiss() } }
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.offshootOnPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Color.offshootPrimary)
        .controlSize(.large)
    }
}
