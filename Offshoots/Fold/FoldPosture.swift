//
//  FoldPosture.swift
//  Offshoots
//

internal import SwiftUI

/// Whether a fold is in the way. `.flat` covers every other device, the closed Duo
/// and the fully open Duo. `.folded` means the Duo is partly open.
enum FoldPosture: Equatable {
    case flat
    /// `bandAxis` is the long axis of the band. `keepOut` is the band plus its margins,
    /// in screen coordinates.
    case folded(bandAxis: Axis, keepOut: CGRect)

    init(regions: [FoldRegion]) {
        guard let region = regions.first else {
            self = .flat
            return
        }
        let frame = region.frame
        let margins = region.margins
        let keepOut = CGRect(
            x: frame.minX - margins.leading,
            y: frame.minY - margins.top,
            width: frame.width + margins.leading + margins.trailing,
            height: frame.height + margins.top + margins.bottom
        )
        self = .folded(bandAxis: frame.width >= frame.height ? .horizontal : .vertical, keepOut: keepOut)
    }
}

/// How a screen sits on the display
enum PaneFit: Equatable {
    /// Use the whole screen
    case fill
    /// A centred column, no wider than `maxWidth`
    case centered(maxWidth: CGFloat)
    /// The pane above the fold
    case top(height: CGFloat)
    /// The pane left of the fold
    case leading(width: CGFloat)
}

extension FoldPosture {
    /// `ownsWideLayout` is true for a screen that builds its own two panes on a wide screen.
    func paneFit(containerWidth: CGFloat, ownsWideLayout: Bool) -> PaneFit {
        if ownsWideLayout, FoldLayout.usesTwoPanes(width: containerWidth) {
            return .fill
        }
        switch self {
        case .flat:
            return .centered(maxWidth: FoldLayout.readableMaxWidth)
        case .folded(.horizontal, let keepOut):
            return .top(height: keepOut.minY)
        case .folded(.vertical, let keepOut):
            return .leading(width: keepOut.minX)
        }
    }
}
