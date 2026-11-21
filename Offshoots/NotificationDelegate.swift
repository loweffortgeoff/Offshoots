//
//  NotificationDelegate.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation
import Combine
import UserNotifications

final class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    /// Where a reminder tap or a widget link wants to go. Held until ContentView consumes it,
    /// so a tap that cold-launches the app isn't lost before the UI is listening.
    @Published var pendingRoute: AppRoute?

    private override init() {}

    // Called when a reminder fires while the app is open; without this iOS hides it
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    // Called when user taps the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {

        let userInfo = response.notification.request.content.userInfo

        if let idString = userInfo["decisionID"] as? String,
           let uuid = UUID(uuidString: idString) {
            pendingRoute = .decision(uuid)
        }
    }
}
