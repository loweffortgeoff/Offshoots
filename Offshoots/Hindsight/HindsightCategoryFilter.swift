internal import SwiftUI

struct HindsightCategoryFilter: View {
    @Binding var selection: DecisionCategory?

    var body: some View {
        Menu {
            Button { selection = nil } label: {
                if selection == nil { Label("All categories", systemImage: "checkmark") }
                else { Text("All categories") }
            }
            ForEach(DecisionCategory.allCases) { category in
                Button { selection = category } label: {
                    if selection == category { Label(category.rawValue.capitalized, systemImage: "checkmark") }
                    else { Text(category.rawValue.capitalized) }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Category").font(.caption).foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline) {
                    Text(selection?.rawValue.capitalized ?? "All categories")
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .tint(Color.offshootPrimary)
        .accessibilityLabel("Category")
        .accessibilityValue(selection?.rawValue.capitalized ?? "All categories")
    }
}
