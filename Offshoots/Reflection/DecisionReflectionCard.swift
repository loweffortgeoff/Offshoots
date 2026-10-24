internal import SwiftUI

struct DecisionReflectionCard: View {
    let decision: Decision
    let sameCategory: [Decision]
    var body: some View { ReflectionReadingCard(kind: .decision(decision.id)) }
}
