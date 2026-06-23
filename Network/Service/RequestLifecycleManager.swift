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

nonisolated extension RequestLifecycleScope {
    static let mainCategoryList = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "mainCategoryList",
            parentTab: .categoryList
        )
    )

    static let homeTodayAnimeScheduleList = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "homeTodayAnimeScheduleList",
            parentTab: .home
        )
    )

    static let homeTrendingAnimeList = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "homeTrendingAnimeList",
            parentTab: .home
        )
    )

    static let homeTrendingMangaList = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "homeTrendingMangaList",
            parentTab: .home
        )
    )

    static let homeWatchList = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "homeWatchList",
            parentTab: .home
        )
    )

    static let mainSearch = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "mainSearch",
            parentTab: .search
        )
    )

    static let mainMyListRandomAnime = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "mainMyListRandomAnime",
            parentTab: .myList
        )
    )

    static let mainMyListRandomManga = RequestLifecycleScope.screen(
        RequestScreenScope(
            identifier: "mainMyListRandomManga",
            parentTab: .myList
        )
    )

    static func animeDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "animeDetail.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func mangaDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "mangaDetail.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func peopleDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "peopleDetail.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func characterDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "characterDetail.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func animeReview(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "animeReview.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func mangaReview(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "mangaReview.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func animeEpisodes(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "animeEpisodes.\(malID).\(instanceID.uuidString)"
            )
        )
    }

    static func animeCategoryDetail(
        genreID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "animeCategoryDetail.\(genreID).\(instanceID.uuidString)"
            )
        )
    }

    static func mangaCategoryDetail(
        genreID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "mangaCategoryDetail.\(genreID).\(instanceID.uuidString)"
            )
        )
    }

    static func producerDetail(
        producerID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "producerDetail.\(producerID).\(instanceID.uuidString)"
            )
        )
    }

    static func producerAnimeList(
        producerID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "producerAnimeList.\(producerID).\(instanceID.uuidString)"
            )
        )
    }
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

// MARK: - RequestLifecycleManaging

nonisolated protocol RequestLifecycleManaging: Sendable {
    func activate(_ scope: RequestLifecycleScope) async
    func deactivate(
        _ scope: RequestLifecycleScope,
        cancelQueued: Bool,
        cancelRunning: Bool
    ) async
    func cancelRequests(in scope: RequestLifecycleScope) async
}

// MARK: - RequestScreenLifecycleController

@MainActor
final class RequestScreenLifecycleController {
    private let scope: RequestLifecycleScope
    private let requestLifecycleManager: any RequestLifecycleManaging
    private var isActive = false

    init(
        scope: RequestLifecycleScope,
        requestLifecycleManager: any RequestLifecycleManaging
    ) {
        self.scope = scope
        self.requestLifecycleManager = requestLifecycleManager
    }

    func activate() async -> Bool {
        isActive = true
        await requestLifecycleManager.activate(scope)
        return isActive && !Task.isCancelled
    }

    func deactivate() {
        isActive = false

        let scope = scope
        let requestLifecycleManager = requestLifecycleManager
        Task { [weak self] in
            await requestLifecycleManager.deactivate(
                scope,
                cancelQueued: true,
                cancelRunning: true
            )

            guard let self, self.isActive else { return }
            await requestLifecycleManager.activate(scope)
        }
    }
}

// MARK: - RequestLifecycleManager

actor RequestLifecycleManager: RequestLifecycleManaging {
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

    private let clock: ContinuousClock
    private let backgroundQuietPeriod: Duration
    private var activeTabScope: JikanAPIRequestScope = .home
    private var inactiveScopes = Set<RequestLifecycleScope>()
    private var pendingRequests: [UUID: PendingRequest] = [:]
    private var runningRequests: [UUID: RunningRequest] = [:]
    private var knownRequestIDs = Set<UUID>()
    private var cancelledPendingRequestIDs = Set<UUID>()
    private var backgroundEligibleInstant: ContinuousClock.Instant
    private var backgroundResumeTask: Task<Void, Never>?

    init(
        backgroundQuietPeriod: Duration = .seconds(2),
        clock: ContinuousClock = ContinuousClock()
    ) {
        self.clock = clock
        self.backgroundQuietPeriod = backgroundQuietPeriod
        self.backgroundEligibleInstant = clock.now.advanced(
            by: backgroundQuietPeriod
        )
    }

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
        if isForeground(resolvedScope) {
            prepareForForegroundRequest()
        }
        defer {
            knownRequestIDs.remove(requestID)
            cancelledPendingRequestIDs.remove(requestID)
        }

        while !isEligible(resolvedScope) {
            try await waitUntilEligible(
                requestID: requestID,
                scope: resolvedScope,
                inactivePolicy: inactivePolicy
            )
        }
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
            requestDidFinish(scope: resolvedScope)
            return value
        } catch {
            runningRequests.removeValue(forKey: requestID)
            requestDidFinish(scope: resolvedScope)
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
        if scope == .background {
            scheduleBackgroundResume()
        }
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
        requestDidFinish(scope: request.scope)
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

    // MARK: - Priority

    private func prepareForForegroundRequest() {
        markForegroundActivity()
        cancelRunningRequests(in: .background)
    }

    private func requestDidFinish(scope: RequestLifecycleScope) {
        if isForeground(scope) {
            markForegroundActivity()
        }
        resumeEligiblePendingRequests()
    }

    private func markForegroundActivity() {
        backgroundEligibleInstant = clock.now.advanced(
            by: backgroundQuietPeriod
        )
        scheduleBackgroundResume()
    }

    private func scheduleBackgroundResume() {
        backgroundResumeTask?.cancel()
        let eligibleInstant = backgroundEligibleInstant
        let clock = clock

        backgroundResumeTask = Task { [weak self] in
            do {
                try await clock.sleep(until: eligibleInstant)
            } catch {
                return
            }
            await self?.resumeBackgroundRequestsIfEligible(
                expectedInstant: eligibleInstant
            )
        }
    }

    private func resumeBackgroundRequestsIfEligible(
        expectedInstant: ContinuousClock.Instant
    ) {
        guard backgroundEligibleInstant == expectedInstant else { return }
        backgroundResumeTask = nil
        resumeEligiblePendingRequests()
    }

    private func hasForegroundRequests() -> Bool {
        pendingRequests.values.contains {
            isForeground($0.scope) && isScopeActive($0.scope)
        }
            || runningRequests.values.contains { isForeground($0.scope) }
    }

    private func isForeground(_ scope: RequestLifecycleScope) -> Bool {
        switch scope {
        case .background:
            return false
        case .tab:
            return true
        case .screen:
            return true
        case .independent:
            return true
        }
    }

    // MARK: - Eligibility

    private func isEligible(_ scope: RequestLifecycleScope) -> Bool {
        guard isScopeActive(scope) else { return false }

        switch scope {
        case .tab(let tabScope):
            return tabScope == activeTabScope

        case .screen(let screenScope):
            guard let parentTab = screenScope.parentTab else { return true }
            return parentTab == activeTabScope

        case .background:
            return !hasForegroundRequests()
                && clock.now >= backgroundEligibleInstant

        case .independent:
            return true
        }
    }

    private func isScopeActive(_ scope: RequestLifecycleScope) -> Bool {
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
