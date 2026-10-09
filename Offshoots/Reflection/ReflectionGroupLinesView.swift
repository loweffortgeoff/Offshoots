//
//  ReflectionGroupLinesView.swift
//  Offshoots
//

internal import SwiftUI

/// One labeled sentence per result group. Patterns and Look Back both show these.
struct ReflectionGroupLinesView: View {
    let lines: [ReflectionGroupLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // One line per result group, so the label is a stable id
            ForEach(lines, id: \.label) { line in
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    Text(line.text)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
