//
//  FoldPostureReader.swift
//  Offshoots
//

internal import SwiftUI

extension EnvironmentValues {
    /// Whether a fold is in the way. `.flat` unless the Duo is partly open.
    @Entry var foldPosture: FoldPosture = .flat
}

extension View {
    /// Reads the fold once and passes it to every view below through `\.foldPosture`.
    func readsFoldPosture() -> some View {
        modifier(FoldPostureReader())
    }
}

private struct FoldPostureReader: ViewModifier {
    @State private var posture: FoldPosture = .flat

    func body(content: Content) -> some View {
        content
            .background { RegionReader(posture: $posture) }
            .environment(\.foldPosture, posture)
    }
}

private struct RegionReader: View {
    @Binding var posture: FoldPosture

    var body: some View {
        if #available(iOS 27.1, *) {
            DivisionRegionReader(posture: $posture)
        } else {
            Color.clear
        }
    }
}

@available(iOS 27.1, *)
private struct DivisionRegionReader: View {
    @Binding var posture: FoldPosture

    var body: some View {
        GeometryReader { proxy in
            let regions = proxy.reservedRegions(kind: .division).map {
                FoldRegion(frame: $0.frame, margins: $0.margins)
            }
            Color.clear
                .onChange(of: regions, initial: true) { _, new in
                    posture = FoldPosture(regions: new)
                    #if DEBUG
                    NSLog("FOLDPOSTURE %@", String(describing: posture))
                    #endif
                }
        }
        .ignoresSafeArea()
    }
}
