//
//  OffshootsApp.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/7/25.
//

internal import SwiftUI

@main
struct OffshootsApp: App {
    /// The splash is a first-launch welcome, not a wait on every launch
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    @State private var showSplash = !UserDefaults.standard.bool(forKey: "hasSeenSplash")
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    /// Owned here, not in ContentView: App.init runs once, while ContentView is
    /// rebuilt when the splash ends and would decode the file again
    @State private var store = DecisionStore()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main App Content
                ContentView()
                    .environment(store)
                    .opacity(showSplash ? 0 : 1) // Fade in when splash is gone
                
                // Splash Screen Overlay
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity) // Fade out transition
                        .zIndex(1) // Ensure it sits on top
                }
            }
            .preferredColorScheme(theme.colorScheme)
            .onAppear {
                guard showSplash else { return }
                // Wait 2 seconds, then dismiss splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                    hasSeenSplash = true
                }
            }
        }
    }
}
