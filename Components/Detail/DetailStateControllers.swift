//
//  DetailStateControllers.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/21.
//

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

@MainActor
final class DetailSupplementaryLoadingController {

    func load<Value: Sendable>(
        resetOnFailure: Bool,
        setLoading: (Bool) -> Void,
        setFailure: (FeatureLoadFailure?) -> Void,
        fetch: () async throws -> Value,
        applyValue: (Value) -> Void,
        resetValue: () -> Void
    ) async {
        setLoading(true)
        if resetOnFailure {
            setFailure(nil)
        }
        defer {
            setLoading(false)
        }

        do {
            applyValue(try await fetch())
            setFailure(nil)
        } catch is CancellationError {
            return
        } catch {
            setFailure(FeatureLoadFailure(error))
            if resetOnFailure {
                resetValue()
            }
        }
    }
}
