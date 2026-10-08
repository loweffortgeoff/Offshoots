//
//  FoldPane.swift
//  Offshoots
//

internal import SwiftUI

/// Fits a whole tab to the display: one half when the Duo is partly open,
/// a centred readable column otherwise. Other iPhones are narrower than the
/// column, so nothing changes for them.
struct FoldPane<Content: View>: View {
    @Environment(\.foldPosture) private var posture
    private let ownsWideLayout: Bool
    private let content: Content

    /// Pass `ownsWideLayout: true` for a screen that builds its own two panes on a wide screen.
    init(ownsWideLayout: Bool = false, @ViewBuilder content: () -> Content) {
        self.ownsWideLayout = ownsWideLayout
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            let fit = posture.paneFit(containerWidth: screenWidth, ownsWideLayout: ownsWideLayout)
            pane(for: fit)
                .onChange(of: fit, initial: true) { _, new in
                    #if DEBUG
                    NSLog("FOLDPANE fit %@ width %.0f safe %@", String(describing: new), screenWidth, String(describing: proxy.safeAreaInsets))
                    #endif
                }
        }
        .background(Color.offshootBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func pane(for fit: PaneFit) -> some View {
        switch fit {
        case .fill:
            content
        case .centered(let maxWidth):
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        case .top(let height):
            content
                .frame(height: height)
                .frame(maxHeight: .infinity, alignment: .top)
        case .leading(let width):
            content
                .frame(width: width)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
