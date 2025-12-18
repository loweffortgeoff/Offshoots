//
//  OffshootsApp.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/7/25.
//

//
//  OffshootsApp.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/7/25.
//

internal import SwiftUI

@main
struct OffshootsApp: App {
    // State to track if splash screen is active
    @State private var showSplash = true

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        ReminderManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main App Content
                ContentView()
                    .opacity(showSplash ? 0 : 1) // Fade in when splash is gone
                
                // Splash Screen Overlay
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity) // Fade out transition
                        .zIndex(1) // Ensure it sits on top
                }
            }
            .onAppear {
                // Wait 2 seconds, then dismiss splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
