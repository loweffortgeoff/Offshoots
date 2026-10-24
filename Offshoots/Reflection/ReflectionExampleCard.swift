internal import SwiftUI

/// Captured from live-sample evaluation on 2026-10-24. See docs/fixtures/reflection-purchase-sample.json.
struct ReflectionExampleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated example · sample decisions").font(.caption).foregroundStyle(.secondary)
            Text("Both decisions involved a purchase made quickly due to a time-sensitive offer.")
            Label("Laptop purchase · Log and first outcome", systemImage: "text.book.closed")
            Label("Annual gym plan · Log and first outcome", systemImage: "text.book.closed")
            Text("Saved with its date and supporting evidence.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}
