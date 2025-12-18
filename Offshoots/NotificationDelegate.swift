//
//  NotificationDelegare.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    private override init() {}

    // Called when user taps the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {

        let userInfo = response.notification.request.content.userInfo

        if let idString = userInfo["decisionID"] as? String,
           let uuid = UUID(uuidString: idString) {
            NotificationCenter.default.post(name: .openDecision, object: uuid)
            
            
            
        }
    }
}

extension Notification.Name {
    static let openDecision = Notification.Name("openDecision")
}
