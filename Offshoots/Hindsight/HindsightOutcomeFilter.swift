internal import SwiftUI

/// A wrapping menu label keeps the chosen value readable at accessibility sizes.
struct HindsightOutcomeFilter: View {
    @Binding var selection: DecisionOutcome?
    var body: some View {
        Menu {
            Button { selection = nil } label: {
                if selection == nil { Label("All outcomes", systemImage: "checkmark") }
                else { Text("All outcomes") }
            }
            ForEach(DecisionOutcome.allCases) { outcome in
                Button { selection = outcome } label: {
                    if selection == outcome { Label(outcome.shortLabel, systemImage: "checkmark") }
                    else { Text(outcome.shortLabel) }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recorded outcome").font(.caption).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline) {
                    Text(selection?.shortLabel ?? "All outcomes")
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .tint(Color.offshootPrimary)
        .accessibilityLabel("Recorded outcome")
        .accessibilityValue(selection?.shortLabel ?? "All outcomes")
    }
}
