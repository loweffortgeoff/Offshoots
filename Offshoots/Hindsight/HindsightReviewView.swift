internal import SwiftUI

struct HindsightReviewView: View {
    let entries: [HindsightEntry]
    @State private var filter = HindsightReviewFilter()

    var body: some View {
        let visible = filter.apply(to: entries)
        List {
            Section {
                ForEach(HindsightAnswer.allCases) { answer in
                    Button { filter.toggle(answer) } label: {
                        HStack {
                            Text(answer.label).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("\(HindsightSummary.count(answer, in: entries))")
                                .monospacedDigit()
                            if filter.answer == answer {
                                Image(systemName: "checkmark").accessibilityHidden(true)
                            }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.offshootPrimary)
                    .accessibilityLabel("\(answer.label), \(HindsightSummary.count(answer, in: entries)) \(HindsightSummary.count(answer, in: entries) == 1 ? "decision" : "decisions")")
                    .accessibilityAddTraits(filter.answer == answer ? .isSelected : [])
                }
            } header: {
                Text(entries.count == 1 ? "1 decision with a recorded answer" : "\(entries.count) decisions with a recorded answer")
            } footer: {
                Text("Each decision counts once. A skipped answer is excluded. Not sure is a recorded answer. Counts include all recorded decisions; filters change the list below.")
            }
            Section {
                HindsightOutcomeFilter(selection: $filter.outcome)
                HindsightCategoryFilter(selection: $filter.category)
                if filter.answer != nil || filter.outcome != nil || filter.category != nil {
                    Button("Clear filters") { filter = HindsightReviewFilter() }
                        .tint(Color.offshootPrimary)
                }
            }
            Section {
                if visible.isEmpty {
                    if entries.isEmpty {
                        Text("No recorded answers. You can add one during an outcome review or revisit.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No recorded check-ins match these filters.")
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(visible) { entry in
                    NavigationLink { HindsightDecisionDestination(entry: entry) } label: {
                        HindsightDecisionRow(entry: entry)
                    }
                }
            } header: { Text("\(visible.count) shown") }
        }
        .scrollContentBackground(.hidden)
        .background(Color.offshootBackground)
        .navigationTitle("Hindsight")
        .navigationBarTitleDisplayMode(.inline)
    }
}
