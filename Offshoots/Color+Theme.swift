//
//  Color+Theme.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/16/25.
//

//
//  Color+Theme.swift
//  Offshoots
//
//  Created by Coding Partner.
//

//
//  Color+Theme.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/16/25.
//

internal import SwiftUI

extension Color {
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Offshoots Muted Botanical Theme
    
    // The Soil (Backgrounds)
    /// Deep Pine Charcoal - Main Background
    static let offshootsBackground = Color(hex: "131614")
    /// Lighter Loam - Surface/Card Background
    static let offshootsSurface    = Color(hex: "232624")
    
    // The Sprout (Brand Accent)
    /// Fern / Matcha - Primary Action & Brand
    static let offshootsAccent     = Color(hex: "A4C639")
    
    // The Fruit (Outcomes)
    /// Deep Sage - Very Good Outcome
    static let offshootsVeryPositive = Color(hex: "5A9A6E")
    /// Sage - Good Outcome
    static let offshootsPositive   = Color(hex: "8FB996")
    /// Sand - Neutral Outcome
    static let offshootsNeutral    = Color(hex: "D0C9B6")
    /// Muted Clay - Bad Outcome
    static let offshootsNegative   = Color(hex: "B87D75")
    /// Deep Clay - Very Bad Outcome
    static let offshootsVeryNegative = Color(hex: "8B4E47")
    
    // MARK: - Semantic Mapping
    // Adaptive colors live in the asset catalog. Xcode generates their
    // symbols: offshootOnPrimary, offshootBackground, offshootCardBackground,
    // outcomeVeryGood, outcomeGood, outcomeNeutral, outcomeBad, outcomeVeryBad.
    // Light mode uses darker shades of the palette so text reaches 4.5:1 on
    // white. Dark mode uses the palette above, on Soil and Loam. The raw
    // palette stays fixed for places that must match the app icon (splash).

    /// Brand primary color (Sprout in dark mode, a darker olive in light mode)
    static let offshootPrimary = Color(.accent)

    /// Pending state (Sand, for a neutral, waiting state)
    static let outcomePending = outcomeNeutral
}

// Helper to map outcomes to colors easily
extension DecisionOutcome {
    var themeColor: Color {
        switch self {
        case .veryGood: return .outcomeVeryGood
        case .good: return .outcomeGood
        case .neutral: return .outcomeNeutral
        case .bad: return .outcomeBad
        case .veryBad: return .outcomeVeryBad
        }
    }
}
