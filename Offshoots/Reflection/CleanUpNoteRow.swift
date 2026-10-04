//
//  CleanUpNoteRow.swift
//  Offshoots
//

internal import SwiftUI

/// Sits under a note field. The user taps `Clean Up Note`, reads the suggestion, then taps
/// `Use` or `Dismiss`. Nothing rewrites by itself, and editing the note clears the suggestion.
/// The call site hides this row when the gate is `hidden`, so the "too long" line never shows
/// on a device that cannot use Reflection.
struct CleanUpNoteRow: View {
    @Binding var text: String

    @Environment(ReflectionCenter.self) private var center
    @State private var run = ReflectionRun<CleanedNote>()

    var body: some View {
        // The VStack stays in the tree for every status, so an edit that makes the note too
        // short or too long still clears a suggestion, and it cannot come back later
        VStack(alignment: .leading, spacing: 0) {
            switch ReflectionEligibility.cleanUpStatus(text) {
            case .tooShort:
                EmptyView()
            case .tooLong:
                Text("This note is too long to clean up. The limit is \(ReflectionEligibility.maximumNoteCharacters) characters.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .ok:
                ReflectionGateView(controlTitle: "Clean Up Note", systemImage: "sparkles") {
                    content
                }
            }
        }
        .onChange(of: text) { run.reset() }
        .onChange(of: run.state) { _, state in
            if case .result = state { AccessibilityNotification.Announcement("Suggestion ready").post() }
        }
    }

    @ViewBuilder private var content: some View {
        switch run.state {
        case .idle:
            Button(action: generate) {
                Label("Clean Up Note", systemImage: "sparkles")
            }
            .buttonStyle(.bordered)
            .tint(Color.offshootPrimary)

        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text("Cleaning up…").font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Cleaning up your note")

        case .result(let cleaned):
            VStack(alignment: .leading, spacing: 12) {
                Text("Suggested note").font(.subheadline).fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Text(cleaned.text).font(.body)
                ViewThatFits(in: .horizontal) {
                    HStack { actions(cleaned) }
                    VStack(alignment: .leading) { actions(cleaned) }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.offshootBackground)
            .cornerRadius(12)

        case .error(let message):
            VStack(alignment: .leading, spacing: 8) {
                Text(message).font(.caption).foregroundStyle(.secondary)
                Button(action: generate) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .tint(Color.offshootPrimary)
            }
        }
    }

    @ViewBuilder private func actions(_ cleaned: CleanedNote) -> some View {
        Button {
            text = cleaned.text
            // A suggestion equal to the note does not change `text`, so clear it here too
            run.reset()
        } label: {
            Label("Use", systemImage: "checkmark")
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.offshootPrimary)
        Button { run.reset() } label: {
            Label("Dismiss", systemImage: "xmark")
        }
        .buttonStyle(.bordered)
        .tint(Color.offshootPrimary)
    }

    private func generate() {
        let generator = center.generator
        let note = text
        run.start { try await generator.cleanUp(note: note) }
    }
}
