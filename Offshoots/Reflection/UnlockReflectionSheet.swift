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
                        Text("Find supported connections in your notes and see how your view changes over time.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ReflectionExampleCard()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reflection adds")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                        ReflectionFeatureRow(title: "Patterns with links to supporting decisions", systemImage: "chart.line.uptrend.xyaxis")
                        ReflectionFeatureRow(title: "A reading of how a decision aged", systemImage: "arrow.triangle.2.circlepath")
                        ReflectionFeatureRow(title: "Dated readings you can keep and revisit", systemImage: "clock")
                    }

                    Text("Generation requires Apple Intelligence on a supported device and language. Patterns need written evidence from at least two separate marked decisions. Unrelated notes may not support a connection. Free Look Back stays free.")
                        .font(.callout).foregroundStyle(.secondary)
                    Text("Clean Up Note is included as a bonus. Review each suggestion before using it.")
                        .font(.callout).foregroundStyle(.secondary)

                    // At accessibility sizes the buttons scroll with the content, so they cannot cover it
                    if dynamicTypeSize.isAccessibilitySize {
                        ReflectionPurchaseControls(purchase: purchase, dismiss: { dismiss() })
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    ReflectionPurchaseControls(purchase: purchase, dismiss: { dismiss() })
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
