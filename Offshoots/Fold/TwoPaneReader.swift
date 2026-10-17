//
//  TwoPaneReader.swift
//  Offshoots
//

internal import SwiftUI

/// Tells its content how the screen arranges its panes: side by side on a foldable device in
/// wide landscape, stacked when the Duo is partly open in portrait. Every other device, and the
/// closed or fully open Duo in portrait, gets one pane.
struct TwoPaneReader<Content: View>: View {
    @Environment(\.foldPosture) private var foldPosture
    private let content: (PaneArrangement) -> Content

    init(@ViewBuilder content: @escaping (PaneArrangement) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            content(foldPosture.arrangement(width: screenWidth))
        }
    }
}
