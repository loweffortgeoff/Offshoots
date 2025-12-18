//
//  OutcomeIcon.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

//
//  OutcomeIcon.swift
//  Offshoots
//
//  Created by Geoffrey Silva on 12/8/25.
//

internal import SwiftUI

struct OutcomeIcon: View {
    let outcome: DecisionOutcome

    var body: some View {
        Image(systemName: symbol)
            .foregroundStyle(outcome.themeColor) // Uses our new theme extension
            .font(.system(size: 20))
    }

    var symbol: String {
        switch outcome {
        case .good: return "checkmark.circle.fill" 
        case .neutral: return "minus.circle.fill"
        case .bad: return "xmark.circle.fill"
        }
    }
}
