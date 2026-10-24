import Foundation
import Observation

/// Owns one provider request. Timeout ends the UI wait even if a provider ignores cancellation.
@MainActor @Observable
final class ReflectionRequestController {
    private(set) var isLoading = false
    private(set) var isProviderBusy = false
    private(set) var error: String?
    private(set) var unsaved: SavedReflection?
    @ObservationIgnored private let generator: any ReflectionGenerating
    @ObservationIgnored private let history: ReflectionHistoryStore
    @ObservationIgnored private let canGenerate: () -> Bool
    @ObservationIgnored private let currentDecisions: () -> [Decision]
    @ObservationIgnored private let epoch: () -> UUID
    @ObservationIgnored private let timeout: Duration
    @ObservationIgnored private var token = UUID()
    @ObservationIgnored private var worker: Task<Void,Never>?
    @ObservationIgnored private var timer: Task<Void,Never>?

    init(generator: any ReflectionGenerating, history: ReflectionHistoryStore, canGenerate: @escaping () -> Bool,
         currentDecisions: @escaping () -> [Decision], epoch: @escaping () -> UUID = { ReflectionRequestController.defaultEpoch }, timeout: Duration = .seconds(20)) {
        self.generator = generator
        self.history = history
        self.canGenerate = canGenerate
        self.currentDecisions = currentDecisions
        self.epoch = epoch
        self.timeout = timeout
    }
    private static let defaultEpoch = UUID()

    func start(kind: SavedReflection.Kind, decisions: [Decision]) {
        guard canGenerate(), !isProviderBusy else { error = "Reflection is not ready for a new request. Try again when it is available."; return }
        let request = UUID()
        token = request
        let startingEpoch = epoch()
        let sources: [Decision]
        if case .decision(let id) = kind { sources = decisions.filter { $0.id == id } } else { sources = decisions }
        let snapshot = ReflectionSourceSnapshot.capture(decisions: sources, subjectID: {
            if case .decision(let id) = kind { return id }; return nil
        }())
        error = nil
        unsaved = nil
        isLoading = true
        isProviderBusy = true
        worker = Task { [weak self] in
            guard let self else { return }
            defer { self.isProviderBusy = false; if self.token == request { self.isLoading = false }; self.timer?.cancel() }
            do {
                let reading: SavedReflection
                switch kind {
                case .patterns:
                    var digest = ReflectionDigestBuilder.patterns(from: decisions)
                    digest.snapshot = snapshot
                    let output = try await generator.patterns(digest: digest)
                    reading = SavedReflection(kind: kind, summary: "", observations: output.observations, snapshot: snapshot)
                case .decision(let id):
                    guard let subject = decisions.first(where: { $0.id == id }),
                          var digest = ReflectionDigestBuilder.decision(subject, among: decisions) else { throw ReflectionError.emptyOutput }
                    digest.snapshot = snapshot
                    let output = try await generator.reflect(on: digest)
                    reading = SavedReflection(kind: kind, summary: output.summary, observations: output.observations, snapshot: snapshot)
                }
                guard !Task.isCancelled, token == request else { return }
                guard canGenerate(), epoch() == startingEpoch,
                      !ReflectionFreshness.status(for: reading, decisions: currentDecisions()).needsRefresh else {
                    error = "The journal or purchase status changed. Request a new reading."; return
                }
                try reading.validate()
                do { try history.append(reading) }
                catch { unsaved = reading; self.error = "This reading was not saved. Your earlier readings are safe. Check storage and try again." }
            } catch is CancellationError {
                if token == request { error = "Reflection was cancelled." }
            } catch {
                if token == request { self.error = (error as? ReflectionError)?.userMessage ?? "Reflection could not finish. Try again." }
            }
        }
        timer = Task { [weak self] in
            do { try await Task.sleep(for: self?.timeout ?? .seconds(20)) } catch { return }
            guard let self, self.token == request, self.isLoading else { return }
            self.cancel()
            self.error = "Reflection took too long. Your saved readings are safe. Try again when the model is ready."
        }
    }
    func cancel() {
        token = UUID()
        worker?.cancel()
        timer?.cancel()
        isLoading = false
    }
    func waitForCompletion() async { await worker?.value }
}
