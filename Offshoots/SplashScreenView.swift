//
//  SplashScreenView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/16/25.
//

internal import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false

    var body: some View {
        // The launch screen (UILaunchScreen in Info.plist) draws LaunchIcon at the centre
        // of the screen. The icon starts at that spot, fully visible, so the hand-off from
        // the launch screen does not jump; only the title animates in below it.
        // Centring on the screen, not the safe area, also keeps the content centred on the
        // closed iPhone Duo, whose side insets differ (camera strip).
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let widest = max(insets.leading, insets.trailing)
            let titleWidth = proxy.size.width + insets.leading + insets.trailing - 2 * widest
            ZStack {
                // Background: Matches App Icon
                Color.offshootsAccent

                // App Icon: the dark icon, sized for the splash (AppIcon images cannot be loaded by name)
                Image("splashicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(alignment: .top) {
                        // App Name
                        Text("Welcome to Offshoots")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.offshootsBackground)
                            .multilineTextAlignment(.center)
                            .frame(width: titleWidth)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: 120 + 24 + (isAnimating ? 0 : 20))
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
