internal import SwiftUI

struct PatternsCard: View {
    let decisions: [Decision]
    let hasNotes: Bool
    var body: some View { ReflectionReadingCard(kind: .patterns) }
}
