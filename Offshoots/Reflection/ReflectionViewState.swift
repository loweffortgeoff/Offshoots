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

    @discardableResult
    func start(_ work: @escaping @MainActor () async throws -> Value) -> Task<Void, Never> {
        task?.cancel()
        state = .loading
        let newTask = Task { [weak self] in
            do {
                let value = try await work()
                guard !Task.isCancelled else { return }
                self?.state = .result(value)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                let reflectionError = error as? ReflectionError ?? .failed
                self?.state = .error(reflectionError.userMessage)
            }
        }
        task = newTask
        return newTask
    }

    func reset() {
        task?.cancel()
        task = nil
        state = .idle
    }
}
