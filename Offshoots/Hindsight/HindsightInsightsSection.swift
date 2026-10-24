internal import SwiftUI

struct HindsightInsightsSection: View {
    let entries: [HindsightEntry]
    @Environment(HindsightAccess.self) private var access
    @State private var showPurchase = false

    var body: some View {
        if access.showsInsights(hasSavedAnswers: !entries.isEmpty) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Hindsight", systemImage: "arrow.uturn.backward").font(.headline)
                if !entries.isEmpty {
                    NavigationLink { HindsightReviewDestination() } label: {
                        Label(entries.count == 1 ? "1 decision with a recorded answer" : "\(entries.count) decisions with a recorded answer",
                              systemImage: "list.bullet")
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    Text("Review what you would repeat or change, beside the outcome recorded at that check-in.")
                        .font(.callout).foregroundStyle(.secondary)
                } else if access.canCapture {
                    Text("Add an optional Hindsight answer when you mark an outcome or revisit a decision. Your recorded answers will appear here.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if access.isEnabled && !access.canCapture {
                    Button("Explore Hindsight") { showPurchase = true }
                        .frame(minHeight: 44)
                    Text("Existing outcomes, notes, and revisits stay free.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .tint(Color.offshootPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.offshootCardBackground, in: RoundedRectangle(cornerRadius: 16))
            .sheet(isPresented: $showPurchase) {
                if let purchase = access.purchase { HindsightPurchaseSheet(purchase: purchase) }
            }
        }
    }
}
