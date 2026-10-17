//
//  FoldPane.swift
//  Offshoots
//

internal import SwiftUI

/// Fits a whole tab to the display: one half when the Duo is partly open, a centred
/// readable column when it is fully open. Every other device, and the closed Duo, keep
/// the whole screen: nothing changes for them, in any orientation.
struct FoldPane<Content: View>: View {
    @Environment(\.foldPosture) private var posture
    private let ownsWideLayout: Bool
    private let content: Content

    /// Pass `ownsWideLayout: true` for a screen that builds its own two panes (side by side on a wide screen, stacked when the Duo is partly open in portrait).
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

    /// One view chain for every fit, with only the numbers changing. A `switch` with one
    /// branch per fit would give each fit its own view identity, and folding the Duo would
    /// rebuild the whole tab and wipe its state (a half-typed Log entry, a pushed screen).
    private func pane(for fit: PaneFit, screenInsets: EdgeInsets) -> some View {
        let sizes = PaneSizes(fit: fit, trailingInset: screenInsets.trailing)
        return content
            .frame(width: sizes.innerWidth)
            .frame(width: sizes.cutWidth, alignment: .leading)
            .frame(maxWidth: sizes.columnMaxWidth)
            .frame(height: sizes.cutHeight)
            .mask {
                // Reaches past the frame on every side except the fold, so backgrounds that
                // ignore the safe area and the navigation bar (a full-screen layer beside the
                // status strip) stay visible. Only the fold edge cuts.
                Rectangle().padding(EdgeInsets(
                    top: -200,
                    leading: -200,
                    bottom: sizes.cutsBottom ? 0 : -200,
                    trailing: sizes.cutsTrailing ? 0 : -200
                ))
            }
            .frame(maxWidth: sizes.outerMaxWidth, maxHeight: sizes.outerMaxHeight, alignment: sizes.alignment)
    }
}

/// The frame numbers for one `PaneFit`. `nil` means "no change".
private struct PaneSizes {
    var innerWidth: CGFloat?
    var cutWidth: CGFloat?
    var columnMaxWidth: CGFloat?
    var cutHeight: CGFloat?
    var cutsBottom = false
    var cutsTrailing = false
    var outerMaxWidth: CGFloat?
    var outerMaxHeight: CGFloat?
    var alignment = Alignment.center

    init(fit: PaneFit, trailingInset: CGFloat) {
        switch fit {
        case .fill:
            break
        case .centered(let maxWidth):
            columnMaxWidth = maxWidth
            outerMaxWidth = .infinity
        case .top(let height):
            cutHeight = height
            cutsBottom = true
            outerMaxHeight = .infinity
            alignment = .top
        case .leading(let width):
            // The tab rail's trailing inset still reaches the content when the pane stops at the
            // fold. Give the content that much extra width and cut it at the fold, so the inset
            // eats the extra. (Checked on the Duo: the cards reach the fold with the normal margin.)
            innerWidth = width + trailingInset
            cutWidth = width
            cutsTrailing = true
            outerMaxWidth = .infinity
            alignment = .leading
        }
    }
}
