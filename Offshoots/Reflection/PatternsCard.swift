//
//  PatternsCard.swift
//  Offshoots
//

internal import SwiftUI

/// Short observations that compare the notes on decisions that went worse, as predicted
/// and better. Built on tap, not saved.
struct PatternsCard: View {
    let decisions: [Decision]
    /// False below `ReflectionEligibility.minimumNotesForPatterns`: a line replaces the control
    let hasNotes: Bool

    @Environment(ReflectionCenter.self) private var center
    @State private var run = ReflectionRun<PatternsOutput>()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Patterns", systemImage: "sparkles", note: "On your device")

            if !hasNotes {
                // Shown to buyers and non-buyers alike: it says what to do, it does not sell
                Text("Patterns read your notes. Add a note when you log or mark a decision.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ReflectionGateView(controlTitle: "Show Patterns", systemImage: "sparkles") {
                    ReflectionStateView(
                        state: run.state,
                        startTitle: "Show Patterns",
                        systemImage: "sparkles",
                        start: generate,
                        copyText: { $0.observations.joined(separator: "\n") }
                    ) { output in
                        VStack(alignment: .leading, spacing: 12) {
                            // Observations are unique after `validated()`, so the text is a stable id
                            ForEach(output.observations, id: \.self) { observation in
                                Text(observation)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        // New or edited decisions make the result stale
        .onChange(of: decisions) { run.reset() }
        .onChange(of: run.state) { _, state in
            if case .result = state { AccessibilityNotification.Announcement("Patterns ready").post() }
        }
    }

    private func generate() {
        let generator = center.generator
        let decisions = decisions
        run.start {
            // The digest is built on tap, so the view's init and body stay cheap
            let digest = ReflectionDigestBuilder.patterns(from: decisions)
            return try await generator.patterns(digest: digest)
        }
    }
}
