//
//  WidePanes.swift
//  Offshoots
//

internal import SwiftUI

/// Two panes side by side on a wide foldable screen. When the Duo is partly open, the
/// system puts the fold between the two.
@available(iOS 27.1, *)
struct WidePanes<Primary: View, Secondary: View>: View {
    private let primary: Primary
    private let secondary: Secondary

    init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary) {
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        ArrangementView {
            primary
        } secondary: {
            secondary
        }
        .arrangementViewStyle(.split.axes(.horizontal))
    }
}
