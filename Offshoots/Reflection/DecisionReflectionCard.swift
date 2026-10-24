internal import SwiftUI

struct DecisionReflectionCard: View {
    let decisionID: UUID
    var body: some View { ReflectionReadingCard(kind: .decision(decisionID)) }
}
