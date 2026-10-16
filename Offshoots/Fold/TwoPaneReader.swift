//
//  TwoPaneReader.swift
//  Offshoots
//

internal import SwiftUI

/// Tells its content whether the screen gets two panes: a foldable device in wide
/// landscape. Every other device, and the Duo in portrait or closed, gets one.
struct TwoPaneReader<Content: View>: View {
    @Environment(\.foldPosture) private var foldPosture
    private let content: (Bool) -> Content

    init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            content(foldPosture.supportsTwoPanes(width: screenWidth))
        }
    }
}
