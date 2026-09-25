//
//  CardTitle.swift
//  Offshoots
//

internal import SwiftUI

/// The title row of an Insights card, with an optional trailing note.
/// At accessibility sizes the decorative icon drops and the note moves under
/// the title, so long single words ("Categories") never break mid-word.
struct CardTitle: View {
    let title: String
    let systemImage: String
    var note: String? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())

        layout {
            Group {
                if isLarge {
                    Text(title)
                } else {
                    Label(title, systemImage: systemImage)
                }
            }
            .font(.headline)
            .foregroundStyle(Color.offshootPrimary)
            .accessibilityAddTraits(.isHeader)

            if let note {
                if !isLarge {
                    Spacer()
                }
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
