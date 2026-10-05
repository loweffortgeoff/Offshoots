//
//  LookBackCard.swift
//  Offshoots
//

internal import SwiftUI

/// On the Log screen, before the prediction: how past decisions in the chosen category went
/// against their predictions, and what their notes share. Built on tap, not saved. It never
/// predicts the new decision or says what to choose.
struct LookBackCard: View {
    let category: DecisionCategory
    /// Marked decisions in `category` only
    let marked: [Decision]

    @Environment(ReflectionCenter.self) private var center
    @State private var run = ReflectionRun<LookBackOutput>()

    private var categoryName: String { category.rawValue.capitalized }
    private var toGo: Int { ReflectionDigestBuilder.minimumHistory - marked.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Look Back", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(Color.offshootPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("How your past \(categoryName) decisions went")
                .font(.caption)
                .foregroundStyle(.secondary)

            if toGo > 0 {
                // Shown to buyers and non-buyers alike: it says what unlocks it, it does not sell
                Text("Look Back needs \(ReflectionDigestBuilder.minimumHistory) marked \(categoryName) decisions. \(toGo) to go.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ReflectionGateView(controlTitle: "Look Back", systemImage: "clock.arrow.circlepath") {
                    ReflectionStateView(
                        state: run.state,
                        startTitle: "Look Back",
                        systemImage: "clock.arrow.circlepath",
                        start: generate,
                        copyText: { ([$0.summary] + $0.lines.map { "\($0.label): \($0.text)" }).joined(separator: "\n") }
                    ) { output in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(output.summary)
                                .font(.body)
                                .fontWeight(.semibold)
                            // One line per result group, so the label is a stable id
                            ForEach(output.lines, id: \.label) { line in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(line.label)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .accessibilityAddTraits(.isHeader)
                                    Text(line.text).font(.body)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        // Another category, or a newly marked decision, makes the result stale
        .onChange(of: category) { run.reset() }
        .onChange(of: marked) { run.reset() }
        .onChange(of: run.state) { _, state in
            if case .result = state { AccessibilityNotification.Announcement("Look Back ready").post() }
        }
    }

    private func generate() {
        let generator = center.generator
        let category = category
        let marked = marked
        run.start {
            guard let digest = ReflectionDigestBuilder.lookBack(category: category, in: marked) else { throw ReflectionError.failed }
            return try await generator.lookBack(digest: digest)
        }
    }
}
