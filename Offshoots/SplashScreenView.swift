//
//  SplashScreenView.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/16/25.
//

//
//  SplashScreenView.swift
//  Offshoots
//
//  Created by Coding Partner.
//

internal import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background: Matches App Icon
            Color.offshootPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Icon
                Image("offshootsdar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.8)

                // App Name
                Text("Welcome to Offshoots")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.offshootBackground)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
