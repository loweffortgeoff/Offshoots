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
            let origin = proxy.frame(in: .global).origin
            let fit = posture.paneFit(containerWidth: screenWidth, ownsWideLayout: ownsWideLayout, containerOrigin: origin)
            pane(for: fit, screenInsets: proxy.safeAreaInsets)
                .onChange(of: fit, initial: true) { _, new in
                    #if DEBUG
                    NSLog("FOLDPANE fit %@ width %.0f origin %@ safe %@", String(describing: new), screenWidth, String(describing: origin), String(describing: proxy.safeAreaInsets))
                    #endif
                }
        }
        .background(Color.offshootBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func pane(for fit: PaneFit, screenInsets: EdgeInsets) -> some View {
        switch fit {
        case .fill:
            content
        case .centered(let maxWidth):
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        case .top(let height):
            // The tab bar's bottom inset still reaches the content when the pane stops at the
            // fold. Give the content that much extra height and clip, so the inset eats the extra.
            content
                .frame(height: height + screenInsets.bottom)
                .frame(height: height, alignment: .top)
                .clipped()
                .frame(maxHeight: .infinity, alignment: .top)
        case .leading(let width):
            // The same for the trailing inset of the tab rail
            content
                .frame(width: width + screenInsets.trailing)
                .frame(width: width, alignment: .leading)
                .clipped()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
