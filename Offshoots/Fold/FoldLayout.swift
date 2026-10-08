//
//  FoldLayout.swift
//  Offshoots
//

internal import SwiftUI

/// The numbers the fold layout uses. Change a number here, not in a view.
enum FoldLayout {
    /// Widest a column grows when no fold is active
    static let readableMaxWidth: CGFloat = 600
    /// Narrowest screen that gets two panes, on a foldable device only (see
    /// `FoldPosture.supportsTwoPanes`). The open Duo in landscape is 951 pt. Width alone
    /// cannot tell it from a Pro Max iPhone in landscape (956 pt).
    static let twoPaneMinWidth: CGFloat = 900

    static func usesTwoPanes(width: CGFloat) -> Bool {
        width >= twoPaneMinWidth
    }
}
