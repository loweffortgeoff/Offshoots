internal import SwiftUI

struct HindsightPurchaseSheet: View {
    let purchase: ReflectionPurchase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                Image("splashicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
                    .padding(.top, 21)

                Text("Keep what you learn from a decision.")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                Text("Record what you would repeat or change. Review those answers beside the outcomes, across your decisions.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                example
                    .padding(.top, 36)

                HindsightPurchaseControls(purchase: purchase, dismiss: { dismiss() })
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.offshootBackground.ignoresSafeArea())
        .presentationBackground(Color.offshootBackground)
        .presentationDragIndicator(.hidden)
        .task { await preparePurchase() }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    closeButton
                    Text("Hindsight")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: 8) {
                    closeButton
                    Text("Hindsight")
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                    closeButton
                        .hidden()
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Text("Close")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.offshootPrimary)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background(Color.offshootCardBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var example: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Illustrative example")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Take on an extra project")
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 8) {
                exampleRow("Outcome: Good", systemImage: "checkmark.circle.fill", tint: .outcomeGood)
                exampleRow("Hindsight: Different approach", systemImage: "arrow.uturn.backward", tint: .offshootPrimary)
            }
            Text("I would still take it on, but agree on the workload first.")
                .font(.body)
            Text("An authored example of a recorded answer and note.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.offshootCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func exampleRow(_ title: String, systemImage: String, tint: Color) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(.primary)
    }

    private func preparePurchase() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-HindsightSheetPreview") {
            purchase.useLayoutFixture(price: "$5.99")
            return
        }
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        await purchase.loadProduct()
    }
}

#if DEBUG
#Preview("Hindsight purchase") {
    let entitlement = ReflectionEntitlement(source: HindsightPreviewEntitlementSource(owned: false))
    let purchase = ReflectionPurchase(
        entitlement: entitlement,
        canPurchase: { false },
        featureName: "Hindsight",
        purchaseBlockedMessage: "Purchases are disabled in this preview."
    )
    purchase.useLayoutFixture(price: "$5.99")
    return HindsightPurchaseSheet(purchase: purchase)
}
#endif
