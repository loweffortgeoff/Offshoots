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
            
            VStack(spacing: 20) {
                // App Name
                Text("Welcome to Offshoots")
                    .font(.largeTitle) // Use a serif font if available, e.g. .custom("Georgia", size: 32)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.offshootBackground)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
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
