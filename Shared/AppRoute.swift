//
//  AppRoute.swift
//  Shared by the app and the widget extension
//

import Foundation

/// A place in the app that a widget link, a notification tap, a Control Center button or (later) a Siri open intent can open.
nonisolated enum AppRoute: Equatable, Hashable, Sendable {
    case log
    case decision(UUID)
    case readyToReview
    case hindsight

    static let scheme = "offshoots"

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        switch url.host {
        case "log" where path.isEmpty: self = .log
        case "revisits" where path.isEmpty: self = .readyToReview
        case "hindsight" where path.isEmpty: self = .hindsight
        case "decision":
            guard path.count == 1, let id = UUID(uuidString: path[0]) else { return nil }
            self = .decision(id)
        default: return nil
        }
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        switch self {
        case .log: components.host = "log"
        case .readyToReview: components.host = "revisits"
        case .hindsight: components.host = "hindsight"
        case .decision(let id):
            components.host = "decision"
            components.path = "/" + id.uuidString
        }
        return components.url!
    }
}
