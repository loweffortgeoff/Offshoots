//
//  FoldRegion.swift
//  Offshoots
//

internal import SwiftUI

/// One reserved region as the app needs it. A plain copy of the system's
/// `ReservedRegion`, so the layout maths is testable without the iOS 27.1 SDK type.
struct FoldRegion: Equatable {
    var frame: CGRect
    var margins: EdgeInsets
}
