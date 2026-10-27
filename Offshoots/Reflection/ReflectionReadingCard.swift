internal import SwiftUI

struct ReflectionReadingCard: View {
    let kind: SavedReflection.Kind
    @Environment(DecisionStore.self) private var store
    @Environment(ReflectionCenter.self) private var center
    @Environment(ReflectionHistoryStore.self) private var history
    @State private var request: ReflectionRequestController?

    private var latest: SavedReflection? { history.readings.last { $0.kind == kind } }
    private var eligible: Bool {
        switch kind {
        case .patterns: ReflectionEligibility.canShowPatterns(for: store.decisions)
        case .decision(let id): store.decisions.first { $0.id == id }.map(ReflectionEligibility.canReflect) ?? false
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardTitle(title: kind.title, systemImage: "sparkles")
            if let latest {
                if !latest.summary.isEmpty { Text(latest.summary) }
                ForEach(latest.observations) { observation in
                    ReflectionObservationView(observation: observation, readingID: latest.id)
                }
                Text(latest.generatedAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
                if ReflectionFreshness.status(for: latest, decisions: store.decisions).needsRefresh {
                    Label("The journal has changed since this reading.", systemImage: "arrow.clockwise")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let error = history.loadError { Text(error).foregroundStyle(.secondary) }
            if let request {
                if let unsaved = request.unsaved {
                    Text("Not saved").font(.headline)
                    if !unsaved.summary.isEmpty { Text(unsaved.summary) }
                    ForEach(unsaved.observations) { Text($0.text) }
                }
                if let error = request.error { Text(error).font(.callout).foregroundStyle(.secondary) }
                if request.isLoading {
                    ProgressView("Reading your decisions…")
                    Button("Cancel", role: .cancel) { request.cancel() }
                } else if eligible {
                    ReflectionGateView(controlTitle: latest == nil ? "Generate" : "Refresh", systemImage: "sparkles") {
                        Button(latest == nil ? "Generate" : "Refresh") { request.start(kind: kind, decisions: store.decisions) }
                            .buttonStyle(.bordered).tint(Color.offshootPrimary)
                            .disabled(request.isProviderBusy || history.loadError != nil)
                    }
                } else {
                    Text(kind == .patterns ? "Add notes to at least two separate marked decisions to look for connections." : "Record an outcome and notes or a revisit to reflect on this decision.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
            NavigationLink { ReflectionHistoryView(kind: nil) } label: {
                Label("Saved Reflections", systemImage: "clock.arrow.circlepath")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.offshootCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if request == nil {
                request = ReflectionRequestController(generator: center.generator, history: history,
                    canGenerate: { center.canGenerate }, currentDecisions: { store.decisions }, epoch: { store.revision })
            }
        }
        // No cancel on disappear: pushing Saved Reflections or switching tabs must not drop a
        // reading in flight. The worker keeps the controller alive and saves to history.
    }
}
