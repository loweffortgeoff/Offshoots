//
//  DecisionReflectionCard.swift
//  Offshoots
//

internal import SwiftUI

/// How one decision aged: a summary, what repeats, and a question for the next revisit.
/// Built on tap, not saved. Not the same thing as `Decision.reflection`, which is the user's
/// own Mark Outcome note.
struct DecisionReflectionCard: View {
    let decision: Decision
    /// Other decisions in the same category, for the history lines in the prompt
    let sameCategory: [Decision]

    @Environment(ReflectionCenter.self) private var center
    @State private var run = ReflectionRun<DecisionReflectionOutput>()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: "Reflection", systemImage: "sparkles", note: "On your device")

            ReflectionGateView(controlTitle: "Reflect on This Decision", systemImage: "sparkles") {
                ReflectionStateView(
                    state: run.state,
                    startTitle: "Reflect on This Decision",
                    systemImage: "sparkles",
                    start: generate,
                    copyText: copyText
                ) { output in
                    ResultBody(output: output, category: decision.category.rawValue.capitalized)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        // A new revisit, an edit or a changed note makes the result stale
        .onChange(of: decision) { run.reset() }
        .onChange(of: sameCategory) { run.reset() }
        .onChange(of: run.state) { _, state in
            if case .result = state { AccessibilityNotification.Announcement("Reflection ready").post() }
        }
    }

    private func generate() {
        let generator = center.generator
        let decision = decision
        let sameCategory = sameCategory
        run.start {
            guard let digest = ReflectionDigestBuilder.decision(decision, among: sameCategory) else { throw ReflectionError.failed }
            return try await generator.reflect(on: digest)
        }
    }

    private func copyText(_ output: DecisionReflectionOutput) -> String {
        ([output.summary, output.echo] + output.repeating + [output.nextPrompt])
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

private struct ResultBody: View {
    let output: DecisionReflectionOutput
    let category: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How it aged").font(.subheadline).fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Text(output.summary).font(.body)
            }
            if !output.echo.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("In other \(category) decisions").font(.subheadline).fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    Text(output.echo).font(.body)
                }
            }
            if !output.repeating.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What is repeating").font(.subheadline).fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    // Lines are unique after `validated()`, so the text is a stable id
                    ForEach(output.repeating, id: \.self) { line in
                        Text(line).font(.body)
                    }
                }
            }
            if !output.nextPrompt.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("For your next revisit").font(.subheadline).fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    Text(output.nextPrompt).font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
