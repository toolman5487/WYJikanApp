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

// MARK: - RequestLifecycleScope Presets

nonisolated extension RequestLifecycleScope {

    // MARK: - Main Tabs

    static let mainHome = mainTabScreen("mainHome", parentTab: .home)
    static let mainCategoryList = mainTabScreen("mainCategoryList", parentTab: .categoryList)
    static let mainNews = mainTabScreen("mainNews", parentTab: .news)
    static let mainSearch = mainTabScreen("mainSearch", parentTab: .search)
    static let mainMyListRandomAnime = mainTabScreen("mainMyListRandomAnime", parentTab: .myList)
    static let mainMyListRandomManga = mainTabScreen("mainMyListRandomManga", parentTab: .myList)

    // MARK: - Home Sub-screens

    static let homeTodayAnimeScheduleList = mainTabScreen(
        "homeTodayAnimeScheduleList",
        parentTab: .home
    )
    static let homeTrendingAnimeList = mainTabScreen("homeTrendingAnimeList", parentTab: .home)
    static let homeTrendingMangaList = mainTabScreen("homeTrendingMangaList", parentTab: .home)
    static let homeWatchList = mainTabScreen("homeWatchList", parentTab: .home)

    // MARK: - Detail Screens

    static func animeDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("animeDetail", resourceID: malID, instanceID: instanceID)
    }

    static func mangaDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("mangaDetail", resourceID: malID, instanceID: instanceID)
    }

    static func peopleDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("peopleDetail", resourceID: malID, instanceID: instanceID)
    }

    static func characterDetail(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("characterDetail", resourceID: malID, instanceID: instanceID)
    }

    static func animeReview(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("animeReview", resourceID: malID, instanceID: instanceID)
    }

    static func mangaReview(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("mangaReview", resourceID: malID, instanceID: instanceID)
    }

    static func animeEpisodes(
        malID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("animeEpisodes", resourceID: malID, instanceID: instanceID)
    }

    static func animeCategoryDetail(
        genreID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("animeCategoryDetail", resourceID: genreID, instanceID: instanceID)
    }

    static func mangaCategoryDetail(
        genreID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("mangaCategoryDetail", resourceID: genreID, instanceID: instanceID)
    }

    static func producerDetail(
        producerID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("producerDetail", resourceID: producerID, instanceID: instanceID)
    }

    static func producerAnimeList(
        producerID: Int,
        instanceID: UUID = UUID()
    ) -> RequestLifecycleScope {
        detailScreen("producerAnimeList", resourceID: producerID, instanceID: instanceID)
    }

    // MARK: - Private

    private static func mainTabScreen(
        _ identifier: String,
        parentTab: JikanAPIRequestScope
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: identifier,
                parentTab: parentTab
            )
        )
    }

    private static func detailScreen(
        _ prefix: String,
        resourceID: Int,
        instanceID: UUID
    ) -> RequestLifecycleScope {
        .screen(
            RequestScreenScope(
                identifier: "\(prefix).\(resourceID).\(instanceID.uuidString)"
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

// MARK: - RequestLifecycleControlling

nonisolated protocol RequestLifecycleControlling: Sendable {
    func activate(_ scope: RequestLifecycleScope) async
    func deactivate(
        _ scope: RequestLifecycleScope,
        cancelQueued: Bool,
        cancelRunning: Bool
    ) async
}

// MARK: - RequestLifecycleExecuting

nonisolated protocol RequestLifecycleExecuting: Sendable {
    func perform<Value: Sendable>(
        scope: RequestLifecycleScope,
        inactivePolicy: RequestInactivePolicy,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value
}

// MARK: - RequestLifecycleManaging

nonisolated protocol RequestLifecycleManaging:
    RequestLifecycleControlling,
    RequestLifecycleExecuting {

    func setActiveTabScope(_ scope: JikanAPIRequestScope) async
}

// MARK: - RequestScreenLifecycleController

nonisolated struct RequestScreenLifecycleToken: Equatable, Sendable {
    fileprivate let generation: UInt64
}

@MainActor
final class RequestScreenLifecycleController {

    // MARK: - Properties

    private let scope: RequestLifecycleScope
    private let requestLifecycleController: any RequestLifecycleControlling
    private var isActive = false
    private var lifecycleGeneration: UInt64 = 0

    // MARK: - Lifecycle

    init(
        scope: RequestLifecycleScope,
        requestLifecycleController: any RequestLifecycleControlling
    ) {
        self.scope = scope
        self.requestLifecycleController = requestLifecycleController
    }

    // MARK: - Public Methods

    func activate() async -> Bool {
        lifecycleGeneration &+= 1
        let activationGeneration = lifecycleGeneration
        isActive = true
        await requestLifecycleController.activate(scope)
        return isActive
            && lifecycleGeneration == activationGeneration
            && !Task.isCancelled
    }

    func activeLifecycleToken() -> RequestScreenLifecycleToken? {
        guard isActive else { return nil }
        return RequestScreenLifecycleToken(generation: lifecycleGeneration)
    }

    var canPresentLifecycleBoundState: Bool {
        isActive && !Task.isCancelled
    }

    func canApplyAsyncResult(for token: RequestScreenLifecycleToken) -> Bool {
        isActive
            && lifecycleGeneration == token.generation
            && !Task.isCancelled
    }

    func shouldRestoreAsyncState(for token: RequestScreenLifecycleToken) -> Bool {
        !isActive || lifecycleGeneration == token.generation
    }

    func deactivate() {
        guard isActive else { return }

        lifecycleGeneration &+= 1
        let deactivationGeneration = lifecycleGeneration
        isActive = false

        let scope = scope
        let requestLifecycleController = requestLifecycleController
        Task(priority: .userInitiated) { @MainActor [weak self] in
            guard let self,
                  !self.isActive,
                  self.lifecycleGeneration == deactivationGeneration else {
                return
            }

            await requestLifecycleController.deactivate(
                scope,
                cancelQueued: true,
                cancelRunning: true
            )
        }
    }
}

// MARK: - RequestLifecycleManager

actor RequestLifecycleManager: RequestLifecycleManaging {

    // MARK: - Types

    private struct PendingRequest {
        let scope: RequestLifecycleScope
        let continuation: CheckedContinuation<Void, Error>
    }

    private struct RunningRequest {
        let scope: RequestLifecycleScope
        let inactivePolicy: RequestInactivePolicy
        let cancel: @Sendable () -> Void
    }

    // MARK: - Properties

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

    // MARK: - Lifecycle

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

    // MARK: - Request Execution

    func perform<Value: Sendable>(
        scope: RequestLifecycleScope,
        inactivePolicy: RequestInactivePolicy = .pauseQueued,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let requestID = UUID()
        knownRequestIDs.insert(requestID)
        if isForeground(scope) {
            prepareForForegroundRequest()
        }
        defer {
            knownRequestIDs.remove(requestID)
            cancelledPendingRequestIDs.remove(requestID)
        }

        while !isEligible(scope) {
            try await waitUntilEligible(
                requestID: requestID,
                scope: scope,
                inactivePolicy: inactivePolicy
            )
        }
        try Task.checkCancellation()

        let task = Task {
            try await operation()
        }
        runningRequests[requestID] = RunningRequest(
            scope: scope,
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
            requestDidFinish(scope: scope)
            return value
        } catch {
            runningRequests.removeValue(forKey: requestID)
            requestDidFinish(scope: scope)
            throw error
        }
    }

    // MARK: - Snapshot

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
}

// MARK: - RequestLifecycleManager Waiting

private extension RequestLifecycleManager {

    func waitUntilEligible(
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

    func registerPendingRequest(
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

    func cancelPendingRequest(requestID: UUID) {
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

    func resumeEligiblePendingRequests() {
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
}

// MARK: - RequestLifecycleManager Cancellation

private extension RequestLifecycleManager {

    func cancelInactiveRequestsIfNeeded() {
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

    func cancelPendingRequests(in scope: RequestLifecycleScope) {
        let requestIDs: [UUID] = pendingRequests.compactMap { requestID, request in
            request.scope == scope ? requestID : nil
        }

        for requestID in requestIDs {
            cancelPendingRequest(requestID: requestID)
        }
    }

    func cancelRunningRequests(in scope: RequestLifecycleScope) {
        for request in runningRequests.values where request.scope == scope {
            request.cancel()
        }
    }
}

// MARK: - RequestLifecycleManager Priority

private extension RequestLifecycleManager {

    func prepareForForegroundRequest() {
        markForegroundActivity()
        cancelRunningRequests(in: .background)
    }

    func requestDidFinish(scope: RequestLifecycleScope) {
        if isForeground(scope) {
            markForegroundActivity()
        }
        resumeEligiblePendingRequests()
    }

    func markForegroundActivity() {
        backgroundEligibleInstant = clock.now.advanced(
            by: backgroundQuietPeriod
        )
        scheduleBackgroundResume()
    }

    func scheduleBackgroundResume() {
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

    func resumeBackgroundRequestsIfEligible(
        expectedInstant: ContinuousClock.Instant
    ) {
        guard backgroundEligibleInstant == expectedInstant else { return }
        backgroundResumeTask = nil
        resumeEligiblePendingRequests()
    }

    func hasForegroundRequests() -> Bool {
        let hasPendingForegroundRequests = pendingRequests.values.contains {
            isForeground($0.scope) && isScopeActive($0.scope)
        }
        let hasRunningForegroundRequests = runningRequests.values.contains {
            isForeground($0.scope)
        }
        return hasPendingForegroundRequests || hasRunningForegroundRequests
    }

    func isForeground(_ scope: RequestLifecycleScope) -> Bool {
        switch scope {
        case .background:
            return false
        case .tab, .screen, .independent:
            return true
        }
    }
}

// MARK: - RequestLifecycleManager Eligibility

private extension RequestLifecycleManager {

    func isEligible(_ scope: RequestLifecycleScope) -> Bool {
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

    func isScopeActive(_ scope: RequestLifecycleScope) -> Bool {
        guard !inactiveScopes.contains(scope) else { return false }

        switch scope {
        case .tab(let tabScope):
            return tabScope == activeTabScope

        case .screen(let screenScope):
            guard let parentTab = screenScope.parentTab else { return true }
            return parentTab == activeTabScope

        case .background, .independent:
            return true
        }
    }

    func requestCounts(
        for scopes: [RequestLifecycleScope]
    ) -> [RequestLifecycleScope: Int] {
        scopes.reduce(into: [:]) { counts, scope in
            counts[scope, default: 0] += 1
        }
    }
}
