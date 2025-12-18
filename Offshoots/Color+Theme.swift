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

internal import SwiftUI

extension Color {
    // MARK: - Brand Colors
    /// A deep, calming forest green for primary actions and headers
    static let offshootPrimary = Color(red: 45/255, green: 78/255, blue: 65/255)
    
    /// A soft organic background (optional, or use system background)
    static let offshootBackground = Color(red: 250/255, green: 249/255, blue: 246/255)
    
    // MARK: - Semantic / Outcome Colors
    /// Sage Green - Success/Good
    static let outcomeGood = Color(red: 106/255, green: 142/255, blue: 109/255)
    
    /// Stone Gray - Neutral
    static let outcomeNeutral = Color(red: 141/255, green: 153/255, blue: 174/255)
    
    /// Muted Terracotta - Bad/Failure (Less aggressive than system Red)
    static let outcomeBad = Color(red: 205/255, green: 91/255, blue: 69/255)
    
    /// Goldenrod - Pending
    static let outcomePending = Color(red: 212/255, green: 163/255, blue: 73/255)
}

// Helper to map outcomes to colors easily
extension DecisionOutcome {
    var themeColor: Color {
        switch self {
        case .good: return .outcomeGood
        case .neutral: return .outcomeNeutral
        case .bad: return .outcomeBad
        }
    }
}
