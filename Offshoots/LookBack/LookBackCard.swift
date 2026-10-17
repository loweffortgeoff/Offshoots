internal import SwiftUI

/// Free prediction history. Reads calculated statistics only, never notes or the model.
struct LookBackCard: View {
    let stats: LookBackStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Look Back", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("How your past \(stats.category) decisions went")
                .font(.caption)
                .foregroundStyle(.secondary)

            if stats.total < LookBackStats.minimumDecisions {
                Text("Look Back needs \(LookBackStats.minimumDecisions) marked \(stats.category) decisions. \(LookBackStats.minimumDecisions - stats.total) to go.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                if let headline = stats.headline {
                    Text(headline)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.offshootPrimary)
                }
                Text(stats.summary)
                    .font(.body)
                LookBackBars(stats: stats)
                Text("Compared with the first outcomes you recorded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    // SwiftUI has no pasteboard API on iOS.
                    UIPasteboard.general.string = [stats.headline, stats.summary]
                        .compactMap { $0 }.joined(separator: "\n")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .tint(Color.offshootPrimary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
    }
}
