//
//  AppPersistenceStore.swift
//  WYJikanApp
//

import Combine

@MainActor
final class AppPersistenceStore: ObservableObject {

    // MARK: - Types

    enum State: Equatable {
        case initializing
        case ready
        case failed(FeatureLoadFailure)
    }

    // MARK: - Properties

    @Published private(set) var state: State = .initializing
    @Published private(set) var initializationAttempt = 0

    var isReady: Bool {
        state == .ready
    }

    // MARK: - State Updates

    func markReady() {
        state = .ready
    }

    func markFailed(_ failure: FeatureLoadFailure) {
        state = .failed(failure)
    }

    func retryInitialization() {
        guard case .failed = state else { return }
        state = .initializing
        initializationAttempt += 1
    }
}
