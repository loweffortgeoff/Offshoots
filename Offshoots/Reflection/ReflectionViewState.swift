//
//  ReflectionViewState.swift
//  Offshoots
//

import Foundation
import Observation

enum ReflectionViewState<Value: Equatable>: Equatable {
    case idle
    case loading
    case result(Value)
    case error(String)
}

/// Runs one generation at a time for one card. Output lives here only, never on disk.
/// A newer `start` or a `reset` cancels the older call, and a cancelled call can never
/// write its result.
@Observable
final class ReflectionRun<Value: Equatable> {
    private(set) var state: ReflectionViewState<Value> = .idle
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored private let timeout: Duration
    @ObservationIgnored private var requestID = UUID()

    init(timeout: Duration = .seconds(20)) { self.timeout = timeout }

    @discardableResult
    func start(_ work: @escaping @MainActor () async throws -> Value) -> Task<Void, Never> {
        task?.cancel()
        timer?.cancel()
        let request = UUID()
        requestID = request
        state = .loading
        let newTask = Task { [weak self] in
            defer { if self?.requestID == request { self?.timer?.cancel() } }
            do {
                let value = try await work()
                guard !Task.isCancelled, self?.requestID == request else { return }
                self?.state = .result(value)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self?.requestID == request else { return }
                let reflectionError = error as? ReflectionError ?? .failed
                self?.state = .error(reflectionError.userMessage)
            }
        }
        task = newTask
        timer = Task { [weak self] in
            do { try await Task.sleep(for: self?.timeout ?? .seconds(20)) } catch { return }
            guard let self, self.requestID == request else { return }
            self.state = .error("Reflection took too long. Your original note is unchanged. Try again.")
            self.task?.cancel()
        }
        return newTask
    }

    func reset() {
        requestID = UUID()
        timer?.cancel()
        task?.cancel()
        task = nil
        state = .idle
    }
}
