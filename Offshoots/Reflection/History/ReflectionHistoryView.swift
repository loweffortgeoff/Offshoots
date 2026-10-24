internal import SwiftUI

struct ReflectionHistoryView: View {
    let kind: SavedReflection.Kind?
    @Environment(ReflectionHistoryStore.self) private var history
    var body: some View {
        List {
            if let error = history.loadError { Text(error) }
            if history.readings.isEmpty {
                Text("Generate a reflection to start your saved history.").foregroundStyle(.secondary)
            }
            ForEach(history.readings.filter { kind == nil || $0.kind == kind }.reversed()) { reading in
                NavigationLink { SavedReflectionView(readingID: reading.id) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reading.kind.title).font(.headline)
                        if case .decision(let id) = reading.kind,
                           let subject = reading.snapshot.decisions.first(where: { $0.id == id }) { Text(subject.title) }
                        Text(reading.generatedAt, format: .dateTime.month().day().year().hour().minute())
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Saved Reflections")
        .navigationBarTitleDisplayMode(.inline)
    }
}
