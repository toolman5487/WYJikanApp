//
//  RequestLifecycleManager.swift
//  WYJikanApp
//

import Foundation

// MARK: - RequestLifecycleScope

nonisolated enum RequestLifecycleScope: Hashable, Sendable {
    case tab(JikanAPIRequestScope)
    case screen(RequestScreenScope)
    case background
    case independent
}

// MARK: - RequestScreenScope

nonisolated struct RequestScreenScope: Hashable, Sendable {
    let identifier: String
    let parentTab: JikanAPIRequestScope?

    init(
        identifier: String,
        parentTab: JikanAPIRequestScope? = nil
    ) {
        self.identifier = identifier
        self.parentTab = parentTab
    }
}

// MARK: - RequestInactivePolicy

nonisolated enum RequestInactivePolicy: Equatable, Sendable {
    case pauseQueued
    case cancel
    case continueRunning
}

// MARK: - RequestLifecycleSnapshot

nonisolated struct RequestLifecycleSnapshot: Sendable {
    let activeTabScope: JikanAPIRequestScope
    let pendingRequestCounts: [RequestLifecycleScope: Int]
    let runningRequestCounts: [RequestLifecycleScope: Int]
}

// MARK: - RequestLifecycleManager

actor RequestLifecycleManager {
    static let shared = RequestLifecycleManager()

    private struct PendingRequest {
        let scope: RequestLifecycleScope
        let continuation: CheckedContinuation<Void, Error>
    }

    private struct RunningRequest {
        let scope: RequestLifecycleScope
        let inactivePolicy: RequestInactivePolicy
        let cancel: @Sendable () -> Void
    }

    private var activeTabScope: JikanAPIRequestScope = .home
    private var inactiveScopes = Set<RequestLifecycleScope>()
    private var pendingRequests: [UUID: PendingRequest] = [:]
    private var runningRequests: [UUID: RunningRequest] = [:]
    private var knownRequestIDs = Set<UUID>()
    private var cancelledPendingRequestIDs = Set<UUID>()

    // MARK: - Scope Lifecycle

    func setActiveTabScope(_ scope: JikanAPIRequestScope) {
        activeTabScope = scope
        cancelInactiveRequestsIfNeeded()
        resumeEligiblePendingRequests()
    }

    func activate(_ scope: RequestLifecycleScope) {
        inactiveScopes.remove(scope)
        resumeEligiblePendingRequests()
    }

    func deactivate(
        _ scope: RequestLifecycleScope,
        cancelQueued: Bool = false,
        cancelRunning: Bool = false
    ) {
        inactiveScopes.insert(scope)
        if cancelQueued {
            cancelPendingRequests(in: scope)
        }

        guard cancelRunning else { return }
        cancelRunningRequests(in: scope)
    }

    func cancelRequests(in scope: RequestLifecycleScope) {
        cancelPendingRequests(in: scope)
        cancelRunningRequests(in: scope)
    }

    func snapshot() -> RequestLifecycleSnapshot {
        RequestLifecycleSnapshot(
            activeTabScope: activeTabScope,
            pendingRequestCounts: requestCounts(
                for: pendingRequests.values.map(\.scope)
            ),
            runningRequestCounts: requestCounts(
                for: runningRequests.values.map(\.scope)
            )
        )
    }

    // MARK: - Request Execution

    func perform<Value: Sendable>(
        scope: RequestLifecycleScope?,
        inactivePolicy: RequestInactivePolicy = .pauseQueued,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let resolvedScope = scope ?? .independent
        let requestID = UUID()
        knownRequestIDs.insert(requestID)
        defer {
            knownRequestIDs.remove(requestID)
            cancelledPendingRequestIDs.remove(requestID)
        }

        try await waitUntilEligible(
            requestID: requestID,
            scope: resolvedScope,
            inactivePolicy: inactivePolicy
        )
        try Task.checkCancellation()

        let task = Task {
            try await operation()
        }
        runningRequests[requestID] = RunningRequest(
            scope: resolvedScope,
            inactivePolicy: inactivePolicy,
            cancel: { task.cancel() }
        )

        do {
            let value = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            runningRequests.removeValue(forKey: requestID)
            return value
        } catch {
            runningRequests.removeValue(forKey: requestID)
            throw error
        }
    }

    // MARK: - Waiting

    private func waitUntilEligible(
        requestID: UUID,
        scope: RequestLifecycleScope,
        inactivePolicy: RequestInactivePolicy
    ) async throws {
        guard !isEligible(scope) else { return }

        switch inactivePolicy {
        case .pauseQueued:
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    registerPendingRequest(
                        requestID: requestID,
                        scope: scope,
                        continuation: continuation
                    )
                }
            } onCancel: {
                Task {
                    await self.cancelPendingRequest(requestID: requestID)
                }
            }

        case .cancel:
            throw CancellationError()

        case .continueRunning:
            return
        }
    }

    private func registerPendingRequest(
        requestID: UUID,
        scope: RequestLifecycleScope,
        continuation: CheckedContinuation<Void, Error>
    ) {
        if cancelledPendingRequestIDs.remove(requestID) != nil {
            continuation.resume(throwing: CancellationError())
            return
        }

        guard !isEligible(scope) else {
            continuation.resume()
            return
        }

        pendingRequests[requestID] = PendingRequest(
            scope: scope,
            continuation: continuation
        )
    }

    private func cancelPendingRequest(requestID: UUID) {
        guard let request = pendingRequests.removeValue(forKey: requestID) else {
            if let request = runningRequests[requestID] {
                request.cancel()
            } else if knownRequestIDs.contains(requestID) {
                cancelledPendingRequestIDs.insert(requestID)
            }
            return
        }
        request.continuation.resume(throwing: CancellationError())
    }

    private func resumeEligiblePendingRequests() {
        let eligibleRequestIDs: [UUID] = pendingRequests.compactMap { requestID, request in
            isEligible(request.scope) ? requestID : nil
        }

        for requestID in eligibleRequestIDs {
            guard let request = pendingRequests.removeValue(forKey: requestID) else {
                continue
            }
            request.continuation.resume()
        }
    }

    // MARK: - Cancellation

    private func cancelInactiveRequestsIfNeeded() {
        let requestIDs: [UUID] = runningRequests.compactMap { requestID, request in
            guard request.inactivePolicy == .cancel,
                  !isEligible(request.scope) else {
                return nil
            }
            return requestID
        }

        for requestID in requestIDs {
            runningRequests[requestID]?.cancel()
        }
    }

    private func cancelPendingRequests(in scope: RequestLifecycleScope) {
        let requestIDs: [UUID] = pendingRequests.compactMap { requestID, request in
            request.scope == scope ? requestID : nil
        }

        for requestID in requestIDs {
            cancelPendingRequest(requestID: requestID)
        }
    }

    private func cancelRunningRequests(in scope: RequestLifecycleScope) {
        for request in runningRequests.values where request.scope == scope {
            request.cancel()
        }
    }

    // MARK: - Eligibility

    private func isEligible(_ scope: RequestLifecycleScope) -> Bool {
        guard !inactiveScopes.contains(scope) else { return false }

        switch scope {
        case .tab(let tabScope):
            return tabScope == activeTabScope

        case .screen(let screenScope):
            guard let parentTab = screenScope.parentTab else { return true }
            return parentTab == activeTabScope

        case .background:
            return true

        case .independent:
            return true
        }
    }

    private func requestCounts(
        for scopes: [RequestLifecycleScope]
    ) -> [RequestLifecycleScope: Int] {
        scopes.reduce(into: [:]) { counts, scope in
            counts[scope, default: 0] += 1
        }
    }
}
