internal import SwiftUI

struct DecisionReflectionResultBody: View {
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
