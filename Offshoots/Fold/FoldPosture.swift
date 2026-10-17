//
//  FoldPosture.swift
//  Offshoots
//

internal import SwiftUI

/// Whether a fold is in the way.
enum FoldPosture: Equatable {
    /// Not a foldable device, or the Duo is closed. Nothing changes for these.
    case flat
    /// The Duo is fully open: a foldable device with nothing in the way
    case unfolded
    /// The Duo is partly open.
    /// `bandAxis` is the long axis of the band. `keepOut` is the band plus its margins,
    /// in screen coordinates.
    case folded(bandAxis: Axis, keepOut: CGRect)

    /// `regions` must include the inactive ones: a foldable device that is fully open
    /// reports only inactive regions, and a device with no fold reports none.
    init(regions: [FoldRegion]) {
        guard let region = regions.first(where: \.isActive) else {
            self = regions.isEmpty ? .flat : .unfolded
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

/// How a screen that owns its layout arranges its panes
enum PaneArrangement: Equatable {
    /// One pane
    case single
    /// Two panes left and right: a foldable device in wide landscape
    case sideBySide
    /// Two panes top and bottom: the Duo partly open in portrait
    case stacked
}

extension FoldPosture {
    /// Side by side needs a foldable device: a Plus or Max iPhone in landscape is as wide as the
    /// open Duo, but has no fold, so it keeps the phone layout. Stacked needs the fold band across
    /// the screen. The fully open Duo in portrait keeps its centred column.
    func arrangement(width: CGFloat) -> PaneArrangement {
        if self != .flat, FoldLayout.usesTwoPanes(width: width) {
            return .sideBySide
        }
        if case .folded(.horizontal, _) = self {
            return .stacked
        }
        return .single
    }

    /// `ownsWideLayout` is true for a screen that builds its own two panes (side by side on a wide screen, stacked when the Duo is partly open in portrait).
    /// `containerOrigin` is where the pane starts on the screen. The safe area can push it
    /// below the top edge, and the fold is measured from the screen edge.
    func paneFit(containerWidth: CGFloat, ownsWideLayout: Bool, containerOrigin: CGPoint = .zero) -> PaneFit {
        if ownsWideLayout, arrangement(width: containerWidth) != .single {
            return .fill
        }
        switch self {
        case .flat:
            return .fill
        case .unfolded:
            return .centered(maxWidth: FoldLayout.readableMaxWidth)
        case .folded(.horizontal, let keepOut):
            return .top(height: max(0, keepOut.minY - containerOrigin.y))
        case .folded(.vertical, let keepOut):
            return .leading(width: max(0, keepOut.minX - containerOrigin.x))
        }
    }
}
