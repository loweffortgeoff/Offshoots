//
//  StarterSuggestionsCard.swift
//  Offshoots
//

internal import SwiftUI

/// Dashboard card for new users: small decisions they can review tomorrow
struct StarterSuggestionsCard: View {
    let suggestions: [StarterSuggestion]
    let onPick: (StarterSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .accessibilityHidden(true)
                    .foregroundStyle(Color.offshootPrimary)
                Text("Try a quick one")
                    .font(.headline)
                    .foregroundStyle(Color.offshootPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            PrimaryCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Small decisions you can review tomorrow. Tap one to start.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 8)

                    ForEach(suggestions) { suggestion in
                        StarterSuggestionRow(title: suggestion.title) {
                            onPick(suggestion)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct StarterSuggestionRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.offshootPrimary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Fills in the Log form")
    }
}

#Preview {
    StarterSuggestionsCard(suggestions: StarterSuggestion.available(given: [])) { _ in }
        .padding()
}
