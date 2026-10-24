internal import SwiftUI

struct HindsightPurchaseSheet: View {
    let purchase: ReflectionPurchase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Keep what you learn from a decision.").font(.largeTitle.bold())
                    Text("Record what you would repeat or change. Review those answers beside the outcomes, across your decisions.")
                        .font(.body).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Illustrative example").font(.caption).foregroundStyle(.secondary)
                        Text("Take on an extra project").font(.headline)
                        Label("Outcome: Good", systemImage: "checkmark.seal")
                        Label("Hindsight: Different approach", systemImage: "arrow.uturn.backward")
                        Text("I would still take it on, but agree on the workload first.")
                            .font(.body)
                        Text("An authored example of a recorded answer and note.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.offshootCardBackground, in: RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Optional check-ins at reviews and revisits", systemImage: "checklist")
                        Label("Dated answers in your decision history", systemImage: "clock")
                        Label("Compare recorded answers with outcomes", systemImage: "line.3.horizontal.decrease")
                    }
                    Text("Works without Apple Intelligence. Saved answers stay readable if ownership changes. Existing notes, outcomes, revisits, and Look Back stay free.")
                        .font(.callout).foregroundStyle(.secondary)
                    if dynamicTypeSize.isAccessibilitySize {
                        HindsightPurchaseControls(purchase: purchase, dismiss: { dismiss() })
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    HindsightPurchaseControls(purchase: purchase, dismiss: { dismiss() })
                        .padding(20).background(Color.offshootBackground)
                }
            }
            .background(Color.offshootBackground)
            .navigationTitle("Hindsight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .task { await purchase.loadProduct() }
        }
    }
}
