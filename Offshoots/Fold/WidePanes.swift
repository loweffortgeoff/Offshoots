//
//  WidePanes.swift
//  Offshoots
//

internal import SwiftUI

/// Two panes on a foldable screen: side by side (`.sideBySide`, wide landscape) or one above
/// the other (`.stacked`, partly open in portrait). When the Duo is partly open, the system
/// puts the fold between the two.
///
/// Side by side, the tab rail sits on the trailing edge, beside the secondary pane. A
/// `NavigationStack` in the primary pane still keeps the rail's trailing inset clear (checked
/// on the Duo: an 84 pt strip inside the pane), although SwiftUI reports no inset inside the
/// pane. So the inset is read outside the split, and the primary pane uses `FoldPane`'s fix: it
/// gets the inset as extra width, and a mask cuts it at its own trailing edge.
///
/// Stacked, the primary pane has no such inset. It only gets the mask, cut at its bottom edge.
/// Checked on the Duo (2026-10-16): the secondary pane needs no inset. Its content scrolls clear
/// of the floating tab bar. The `FOLDPANE` debug lines show each pane's size and safe area.
@available(iOS 27.1, *)
struct WidePanes<Primary: View, Secondary: View>: View {
    private let arrangement: PaneArrangement
    private let primary: Primary
    private let secondary: Secondary

    /// `arrangement` is `.sideBySide` or `.stacked`; `.single` has no panes to arrange.
    init(arrangement: PaneArrangement, @ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Secondary) {
        assert(arrangement != .single, "WidePanes needs two panes")
        self.arrangement = arrangement
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        let stacked = arrangement == .stacked
        GeometryReader { outer in
            // One view chain for both arrangements, with only the numbers changing, so a
            // rotation between partly open portrait and landscape keeps the panes' identity.
            let railInset = stacked ? 0 : outer.safeAreaInsets.trailing
            ArrangementView {
                GeometryReader { pane in
                    primary
                        .frame(width: pane.size.width + railInset)
                        .frame(width: pane.size.width, alignment: .leading)
                        .mask {
                            // Reaches past every edge except the one facing the other pane, as in `FoldPane`
                            Rectangle().padding(EdgeInsets(
                                top: -200,
                                leading: -200,
                                bottom: stacked ? 0 : -200,
                                trailing: stacked ? -200 : 0
                            ))
                        }
                        .logsPane("primary", arrangement: arrangement, outer: outer)
                }
            } secondary: {
                secondary
                    .logsPane("secondary", arrangement: arrangement, outer: outer)
            }
            .arrangementViewStyle(.split.axes(stacked ? .vertical : .horizontal))
        }
    }
}

private extension View {
    /// DEBUG only: logs a pane's size and safe area. Read with
    /// `simctl spawn <UDID> log show --last 30s --info --predicate 'eventMessage CONTAINS "FOLDPANE"'`.
    @ViewBuilder
    func logsPane(_ name: String, arrangement: PaneArrangement, outer: GeometryProxy) -> some View {
        #if DEBUG
        background {
            GeometryReader { pane in
                Color.clear
                    .onChange(of: pane.size, initial: true) { _, size in
                        NSLog(
                            "FOLDPANE %@ %@ size %@ safe %@ outerSafe %@",
                            String(describing: arrangement), name, String(describing: size),
                            String(describing: pane.safeAreaInsets), String(describing: outer.safeAreaInsets)
                        )
                    }
            }
        }
        #else
        self
        #endif
    }
}
