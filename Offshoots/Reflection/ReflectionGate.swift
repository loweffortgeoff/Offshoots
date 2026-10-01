//
//  ReflectionGate.swift
//  Offshoots
//

import Foundation

/// What the device can do right now. Built by `LiveReflectionService`; the gate never sees the SDK.
enum ModelAvailability: Equatable {
    case available
    /// A supported device whose model cannot answer yet (still downloading, or busy)
    case notReady(reason: String)
    /// Older iOS, ineligible device, Apple Intelligence off, simulator or unsupported language
    case unsupported
}

/// What a Reflection control looks like on screen.
enum ReflectionSurfaceState: Equatable {
    case hidden
    case notReady(reason: String)
    case paywalled
    case enabled
}

enum ReflectionGate {
    /// The paywall appears only where the model works, so nobody buys what they cannot use.
    static func state(availability: ModelAvailability, isUnlocked: Bool) -> ReflectionSurfaceState {
        switch availability {
        case .unsupported: .hidden
        case .notReady(let reason): .notReady(reason: reason)
        case .available: isUnlocked ? .enabled : .paywalled
        }
    }
}
