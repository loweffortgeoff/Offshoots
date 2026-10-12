//
//  OffshootsApp.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/7/25.
//

internal import SwiftUI

@main
struct OffshootsApp: App {
    /// The splash shows on the first cold launch of each day, not on every launch
    @AppStorage(SplashSchedule.storageKey) private var lastSplashDate: Double = 0
    @State private var showSplash = SplashSchedule.isDue(lastShown: UserDefaults.standard.double(forKey: SplashSchedule.storageKey))
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .system
    /// Owned here, not in ContentView: App.init runs once, while ContentView is
    /// rebuilt when the splash ends and would decode the file again
    @State private var store = DecisionStore()
    @State private var reflection = ReflectionCenter.make()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main App Content
                ContentView()
                    .environment(store)
                    .environment(reflection)
                    .opacity(showSplash ? 0 : 1) // Fade in when splash is gone
                
                // Splash Screen Overlay
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity) // Fade out transition
                        .zIndex(1) // Ensure it sits on top
                }
            }
            .preferredColorScheme(theme.colorScheme)
            .task { await reflection.start() }
            .onAppear {
                guard showSplash else { return }
                // Wait 2 seconds, then dismiss splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                    lastSplashDate = Date.now.timeIntervalSinceReferenceDate
                }
            }
            .onChange(of: scenePhase) { _, phase in
                // The model can finish downloading while the app is in the background
                if phase == .active { reflection.refreshAvailability() }
            }
        }
    }
}
