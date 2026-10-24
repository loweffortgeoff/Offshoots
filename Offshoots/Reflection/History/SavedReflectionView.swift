internal import SwiftUI

struct SavedReflectionView: View {
    let readingID: UUID
    @Environment(ReflectionHistoryStore.self) private var history
    @Environment(DecisionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let reading = history.readings.first(where: { $0.id == readingID }) {
                    Text(reading.generatedAt, format: .dateTime.month().day().year().hour().minute())
                        .foregroundStyle(.secondary)
                    if !reading.summary.isEmpty { Text(reading.summary) }
                    ForEach(reading.observations) { ReflectionObservationView(observation: $0, readingID: reading.id) }
                    Text(reading.snapshot.scope).font(.caption).foregroundStyle(.secondary)
                    if ReflectionFreshness.status(for: reading, decisions: store.decisions).needsRefresh {
                        Text("The source records have changed. This is the reading and evidence saved at generation.")
                            .foregroundStyle(.secondary)
                    }
                    Button("Delete Saved Reflection", role: .destructive) { confirmDelete = true }
                } else { Text("This saved reflection was deleted.") }
                if let error { Text(error) }
            }.padding().frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Saved Reflection").navigationBarTitleDisplayMode(.inline)
        .background(Color.offshootBackground)
        .confirmationDialog("Delete this saved reflection?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                do { try history.delete(id: readingID); dismiss() }
                catch { self.error = "The reading could not be deleted. Try again." }
            }
        } message: { Text("This removes the reading and its retained evidence. Journal decisions stay in place.") }
    }
}
