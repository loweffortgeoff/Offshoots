//
//  WidePanes.swift
//  Offshoots
//

internal import SwiftUI

/// Two panes side by side on a wide foldable screen. When the Duo is partly open, the
/// system puts the fold between the two.
///
/// The tab rail sits on the trailing edge, beside the secondary pane. A `NavigationStack`
/// in the primary pane still keeps the rail's trailing inset clear (checked on the Duo: an
/// 84 pt strip inside the pane), although SwiftUI reports no inset inside the pane. So the
/// inset is read outside the split, and the primary pane uses `FoldPane`'s fix: it gets the
/// inset as extra width, and a mask cuts it at its own trailing edge.
@available(iOS 27.1, *)
struct WidePanes<Primary: View, Secondary: View>: View {
    private let primary: Primary
    private let secondary: Secondary

    init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary) {
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        GeometryReader { outer in
            let railInset = outer.safeAreaInsets.trailing
            ArrangementView {
                GeometryReader { pane in
                    primary
                        .frame(width: pane.size.width + railInset)
                        .frame(width: pane.size.width, alignment: .leading)
                        .mask {
                            // Reaches past every edge except the trailing one, as in `FoldPane`
                            Rectangle().padding(EdgeInsets(top: -200, leading: -200, bottom: -200, trailing: 0))
                        }
                }
            } secondary: {
                secondary
            }
            .arrangementViewStyle(.split.axes(.horizontal))
        }
    }
}
