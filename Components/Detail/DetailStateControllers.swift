//
//  DetailStateControllers.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/21.
//

import Combine
import Foundation
import OSLog

// MARK: - PersistenceMutationState

nonisolated enum PersistenceMutationState: Equatable, Sendable {
    case idle
    case processing
    case failed(message: String)

    var isProcessing: Bool {
        self == .processing
    }

    var failureMessage: String? {
        guard case .failed(let message) = self else { return nil }
        return message
    }
}

// MARK: - PersistenceMutationController

@MainActor
final class PersistenceMutationController {

    func perform(
        failureMessage: String,
        logPrefix: String,
        operation: () throws -> Void
    ) -> PersistenceMutationState {
        do {
            try operation()
            return .idle
        } catch {
            AppLogger.persistence.error(
                "\(logPrefix, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return .failed(message: failureMessage)
        }
    }
}

// MARK: - DetailSupplementaryLoadingController

nonisolated enum DetailSupplementaryLoadResult: Sendable {
    case completed
    case cancelled
    case failed(FeatureLoadFailure)
}

@MainActor
final class DetailSupplementaryState<Value>: ObservableObject {

    @Published private(set) var value: Value
    @Published private(set) var isLoading = false
    @Published private(set) var failure: FeatureLoadFailure?

    init(initialValue: Value) {
        self.value = initialValue
    }

    func beginLoading(resetOnFailure: Bool) {
        isLoading = true
        if resetOnFailure {
            failure = nil
        }
    }

    func finishLoading(with value: Value) {
        self.value = value
        failure = nil
        isLoading = false
    }

    func finishLoading(
        with failure: FeatureLoadFailure,
        resetValueTo value: Value?
    ) {
        self.failure = failure
        if let value {
            self.value = value
        }
        isLoading = false
    }

    func finishCancelledLoading() {
        isLoading = false
    }

    func reset(to value: Value) {
        self.value = value
        isLoading = false
        failure = nil
    }
}

@MainActor
final class DetailSupplementaryLoadingController {

    func load<Value: Sendable>(
        state: DetailSupplementaryState<Value>,
        resetOnFailure: Bool,
        startsLoading: Bool = true,
        resetValue: @autoclosure () -> Value,
        shouldApplyResult: () -> Bool = { true },
        fetch: () async throws -> Value
    ) async -> DetailSupplementaryLoadResult {
        if startsLoading {
            state.beginLoading(resetOnFailure: resetOnFailure)
        }

        do {
            let value = try await fetch()
            guard shouldApplyResult() else {
                state.finishCancelledLoading()
                return .cancelled
            }
            state.finishLoading(with: value)
            return .completed
        } catch is CancellationError {
            state.finishCancelledLoading()
            return .cancelled
        } catch {
            guard shouldApplyResult() else {
                state.finishCancelledLoading()
                return .cancelled
            }
            let failure = FeatureLoadFailure(error)
            state.finishLoading(
                with: failure,
                resetValueTo: resetOnFailure ? resetValue() : nil
            )
            return .failed(failure)
        }
    }
}
