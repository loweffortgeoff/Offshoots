//
//  StarterSuggestionsSection.swift
//  Offshoots
//

internal import SwiftUI

struct StarterSuggestionsSection: View {
    @Environment(DecisionStore.self) private var store
    @Binding var logDraft: StarterSuggestion?
    @Binding var selectedTab: AppTab

    var body: some View {
        let suggestions = StarterSuggestion.available(given: store.decisions)
        if !suggestions.isEmpty {
            StarterSuggestionsCard(suggestions: suggestions) { suggestion in
                logDraft = suggestion
                selectedTab = .log
            }
        }
    }
}

#Preview {
    StarterSuggestionsSection(logDraft: .constant(nil), selectedTab: .constant(.dashboard))
        .environment(DecisionStore())
}
