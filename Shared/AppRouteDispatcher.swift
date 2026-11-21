//
//  AppRouteDispatcher.swift
//  Shared by the app and the widget extension
//

import Foundation

/// Hands a route from an in-process AppIntent (`openAppWhenRun = true`) to the app's router
/// without `Shared/` importing app-only types such as `NotificationDelegate`.
/// Queues any route sent before the app registers its handler so cold launches never drop a tap.
@MainActor
final class AppRouteDispatcher {
    static let shared = AppRouteDispatcher()

    private var handler: ((AppRoute) -> Void)?
    private var queued: AppRoute?

    init() {}

    func register(_ handler: @escaping (AppRoute) -> Void) {
        self.handler = handler
        if let pending = queued {
            queued = nil
            handler(pending)
        }
    }

    func send(_ route: AppRoute) {
        if let handler {
            handler(route)
        } else {
            queued = route
        }
    }
}
