//
//  HomeFeedCoordinator.swift
//  WYJikanApp
//

import Combine
import Foundation

// MARK: - HomeFeedLoadTier

enum HomeFeedLoadTier: Int, CaseIterable, Sendable {
    case phase1
    case phase2
    case phase3
    case deferred

    static var initialTiers: [HomeFeedLoadTier] {
        [.phase1, .phase2, .phase3]
    }

    var sections: [HomeFeedSection] {
        switch self {
        case .phase1:
            return [.heroBanner, .todayAnime]
        case .phase2:
            return [.watchPromos, .watchEpisodes]
        case .phase3:
            return [.trendingAnime, .trendingManga]
        case .deferred:
            return [.recommendedAnime]
        }
    }
}

// MARK: - HomeFeedSectionLoadState

enum HomeFeedSectionLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed
    case deferredPending

    var permitsLoad: Bool {
        switch self {
        case .idle, .failed:
            return true
        case .loading, .loaded, .deferredPending:
            return false
        }
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}

// MARK: - HomeFeedSection

enum HomeFeedSection: Hashable, CaseIterable {
    case heroBanner
    case todayAnime
    case trendingAnime
    case trendingManga
    case watchPromos
    case watchEpisodes
    case recommendedAnime

    var loadTier: HomeFeedLoadTier {
        switch self {
        case .heroBanner, .todayAnime:
            return .phase1
        case .watchPromos, .watchEpisodes:
            return .phase2
        case .trendingAnime, .trendingManga:
            return .phase3
        case .recommendedAnime:
            return .deferred
        }
    }

    var isDeferred: Bool {
        loadTier == .deferred
    }
}

// MARK: - HomeFeedBootstrapMilestone

nonisolated enum HomeFeedBootstrapMilestone: Int, CaseIterable, Sendable {
    case coreFeedsReady
    case allFeedsReady
}

// MARK: - HomeFeedBootstrapCoordinating

nonisolated protocol HomeFeedBootstrapCoordinating: Sendable {
    func wait(for milestone: HomeFeedBootstrapMilestone) async
    func markCompleted(_ milestone: HomeFeedBootstrapMilestone) async
}

// MARK: - HomeFeedBootstrapCoordinator

actor HomeFeedBootstrapCoordinator: HomeFeedBootstrapCoordinating {

    // MARK: - Properties

    private var completedMilestones = Set<HomeFeedBootstrapMilestone>()
    private var waiters: [HomeFeedBootstrapMilestone: [CheckedContinuation<Void, Never>]] = [:]

    // MARK: - Public Methods

    func wait(for milestone: HomeFeedBootstrapMilestone) async {
        guard !completedMilestones.contains(milestone) else { return }

        await withCheckedContinuation { continuation in
            waiters[milestone, default: []].append(continuation)
        }
    }

    func markCompleted(_ milestone: HomeFeedBootstrapMilestone) {
        for completedMilestone in HomeFeedBootstrapMilestone.allCases where completedMilestone.rawValue <= milestone.rawValue {
            complete(completedMilestone)
        }
    }

    // MARK: - Private Methods

    private func complete(_ milestone: HomeFeedBootstrapMilestone) {
        guard completedMilestones.insert(milestone).inserted else { return }

        let pendingWaiters = waiters.removeValue(forKey: milestone) ?? []
        pendingWaiters.forEach { $0.resume() }
    }
}

// MARK: - HomeDeferredSectionLoadScheduler

private actor HomeDeferredSectionLoadScheduler {

    // MARK: - Properties

    private let initialDelay: Duration
    private let requestInterval: Duration
    private var nextAllowedInstant: ContinuousClock.Instant?

    // MARK: - Lifecycle

    init(
        initialDelay: Duration = .seconds(1),
        requestInterval: Duration = .seconds(1)
    ) {
        self.initialDelay = initialDelay
        self.requestInterval = requestInterval
    }

    // MARK: - Public Methods

    func waitForTurn() async throws {
        let clock = ContinuousClock()
        let now = clock.now
        let scheduledInstant: ContinuousClock.Instant

        if let nextAllowedInstant {
            scheduledInstant = max(nextAllowedInstant, now)
        } else {
            scheduledInstant = now.advanced(by: initialDelay)
        }

        nextAllowedInstant = scheduledInstant.advanced(by: requestInterval)
        try await clock.sleep(until: scheduledInstant)
    }
}

// MARK: - HomeFeedViewModels

struct HomeFeedViewModels {
    let heroBanner: HeroBannerViewModel
    let todayAnime: HomeTodayAnimeViewModel
    let trendingAnime: HomeTrendingAnimeViewModel
    let trendingManga: HomeTrendingMangaViewModel
    let watchPromos: HomeWatchPromosViewModel
    let watchEpisodes: HomeWatchEpisodesViewModel
    let recommendedAnime: HomeRecommendedAnimeViewModel
}

// MARK: - HomeFeedInitialLoadable

@MainActor
private protocol HomeFeedInitialLoadable: AnyObject {
    var isFeedLoadSuccessful: Bool { get }
    func loadIfNeeded(priority: TaskPriority)
    func refresh() async
}

// MARK: - HomeFeedInitialLoadable Conformance

extension HeroBannerViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

extension HomeTodayAnimeViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

extension HomeTrendingAnimeViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

extension HomeTrendingMangaViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

extension HomeWatchPromosViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

extension HomeWatchEpisodesViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

extension HomeRecommendedAnimeViewModel: HomeFeedInitialLoadable {
    var isFeedLoadSuccessful: Bool { screenState.isLoadSuccessful }
}

// MARK: - HomeFeedCoordinator

@MainActor
final class HomeFeedCoordinator {

    // MARK: - Properties

    private let viewModels: HomeFeedViewModels
    private let homeFeedBootstrapCoordinator: any HomeFeedBootstrapCoordinating
    private let requestLifecycleController: RequestScreenLifecycleController
    private let deferredSectionLoadScheduler = HomeDeferredSectionLoadScheduler()
    private var sectionStates: [HomeFeedSection: HomeFeedSectionLoadState] = [:]

    // MARK: - Lifecycle

    init(
        viewModels: HomeFeedViewModels,
        homeFeedBootstrapCoordinator: any HomeFeedBootstrapCoordinating,
        requestLifecycleController: any RequestLifecycleControlling
    ) {
        self.viewModels = viewModels
        self.homeFeedBootstrapCoordinator = homeFeedBootstrapCoordinator
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: .mainHome,
            requestLifecycleController: requestLifecycleController
        )
    }

    // MARK: - Public Methods

    func screenDidAppear() async -> Bool {
        await requestLifecycleController.activate()
    }

    func screenDidDisappear() {
        requestLifecycleController.deactivate()
    }

    func loadInitial() async {
        AppLaunchSignposter.beginHomeInitialLoad()
        defer {
            AppLaunchSignposter.endHomeInitialLoad()
        }

        for tier in HomeFeedLoadTier.initialTiers {
            await loadTier(tier, priority: .userInitiated)
        }
        await homeFeedBootstrapCoordinator.markCompleted(.coreFeedsReady)
    }

    func loadSectionIfNeeded(_ section: HomeFeedSection) async {
        guard section.isDeferred else { return }
        await homeFeedBootstrapCoordinator.wait(for: .coreFeedsReady)
        guard !Task.isCancelled else { return }
        await loadDeferredSection(section, priority: .utility)
    }

    func loadDeferredSections(
        priority: TaskPriority,
        sectionDelay: Duration = .zero
    ) async {
        if sectionDelay > .zero {
            try? await Task.sleep(for: sectionDelay)
        }

        for section in HomeFeedLoadTier.deferred.sections {
            await loadDeferredSection(section, priority: priority)
        }
    }

    func refreshAll() async {
        for tier in HomeFeedLoadTier.initialTiers {
            await refreshTier(tier)
        }
        await refreshTier(.deferred)
    }

    // MARK: - Tier Loading

    private func loadTier(_ tier: HomeFeedLoadTier, priority: TaskPriority) async {
        let sections = tier.sections
        guard sections.count == 2 else { return }
        await loadSectionsConcurrently(sections[0], sections[1], priority: priority)
    }

    private func refreshTier(_ tier: HomeFeedLoadTier) async {
        let sections = tier.sections
        guard sections.count == 2 else {
            for section in sections {
                await refresh(section)
            }
            return
        }
        await refreshSectionsConcurrently(sections[0], sections[1])
    }

    private func loadSectionsConcurrently(
        _ first: HomeFeedSection,
        _ second: HomeFeedSection,
        priority: TaskPriority
    ) async {
        async let firstLoad = load(first, priority: priority)
        async let secondLoad = load(second, priority: priority)
        _ = await (firstLoad, secondLoad)
    }

    private func refreshSectionsConcurrently(_ first: HomeFeedSection, _ second: HomeFeedSection) async {
        async let firstRefresh = refresh(first)
        async let secondRefresh = refresh(second)
        _ = await (firstRefresh, secondRefresh)
    }

    // MARK: - Section Operations

    private func loadDeferredSection(
        _ section: HomeFeedSection,
        priority: TaskPriority
    ) async {
        guard section.isDeferred, beginDeferredLoad(for: section) else { return }
        defer { endDeferredLoad(for: section) }

        do {
            try await deferredSectionLoadScheduler.waitForTurn()
        } catch is CancellationError {
            return
        } catch {
            return
        }

        guard !Task.isCancelled else { return }
        await load(section, priority: priority)
    }

    private func load(_ section: HomeFeedSection, priority: TaskPriority) async {
        guard beginLoad(for: section) else { return }

        let isSuccessful = switch section {
        case .heroBanner:
            await loadIfNeeded(viewModels.heroBanner, priority: priority)
        case .todayAnime:
            await loadIfNeeded(viewModels.todayAnime, priority: priority)
        case .trendingAnime:
            await loadIfNeeded(viewModels.trendingAnime, priority: priority)
        case .trendingManga:
            await loadIfNeeded(viewModels.trendingManga, priority: priority)
        case .watchPromos:
            await loadIfNeeded(viewModels.watchPromos, priority: priority)
        case .watchEpisodes:
            await loadIfNeeded(viewModels.watchEpisodes, priority: priority)
        case .recommendedAnime:
            await loadIfNeeded(viewModels.recommendedAnime, priority: priority)
        }

        await finishLoad(for: section, isSuccessful: isSuccessful)
    }

    private func refresh(_ section: HomeFeedSection) async {
        let isSuccessful = switch section {
        case .heroBanner:
            await refresh(viewModels.heroBanner)
        case .todayAnime:
            await refresh(viewModels.todayAnime)
        case .trendingAnime:
            await refresh(viewModels.trendingAnime)
        case .trendingManga:
            await refresh(viewModels.trendingManga)
        case .watchPromos:
            await refresh(viewModels.watchPromos)
        case .watchEpisodes:
            await refresh(viewModels.watchEpisodes)
        case .recommendedAnime:
            await refresh(viewModels.recommendedAnime)
        }

        await finishLoad(for: section, isSuccessful: isSuccessful)
    }

    private func loadIfNeeded(
        _ viewModel: some HomeFeedInitialLoadable,
        priority: TaskPriority
    ) async -> Bool {
        guard !viewModel.isFeedLoadSuccessful else { return true }
        viewModel.loadIfNeeded(priority: priority)
        await viewModel.refresh()
        return viewModel.isFeedLoadSuccessful
    }

    private func refresh(_ viewModel: some HomeFeedInitialLoadable) async -> Bool {
        await viewModel.refresh()
        return viewModel.isFeedLoadSuccessful
    }

    private func sectionState(for section: HomeFeedSection) -> HomeFeedSectionLoadState {
        sectionStates[section, default: .idle]
    }

    private func beginLoad(for section: HomeFeedSection) -> Bool {
        switch sectionState(for: section) {
        case .idle, .failed, .deferredPending:
            sectionStates[section] = .loading
            return true
        case .loading, .loaded:
            return false
        }
    }

    private func beginDeferredLoad(for section: HomeFeedSection) -> Bool {
        switch sectionState(for: section) {
        case .idle, .failed:
            sectionStates[section] = .deferredPending
            return true
        case .loading, .loaded, .deferredPending:
            return false
        }
    }

    private func endDeferredLoad(for section: HomeFeedSection) {
        if sectionState(for: section) == .deferredPending {
            sectionStates[section] = .idle
        }
    }

    private func finishLoad(for section: HomeFeedSection, isSuccessful: Bool) async {
        sectionStates[section] = isSuccessful ? .loaded : .failed

        guard HomeFeedSection.allCases.allSatisfy({ sectionState(for: $0).isLoaded }) else {
            return
        }
        await homeFeedBootstrapCoordinator.markCompleted(.allFeedsReady)
    }
}

// MARK: - HomeFeedSectionLoader

@MainActor
final class HomeFeedSectionLoader {

    // MARK: - Nested Types

    enum State {
        case idle
        case loading(Task<Void, Never>)

        fileprivate var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    // MARK: - Properties

    private(set) var state: State = .idle
    private var activeTask: Task<Void, Never>?

    var isLoading: Bool { state.isLoading }

    var task: Task<Void, Never>? { activeTask }

    // MARK: - Public Methods

    func loadIfNeeded(isContentEmpty: Bool, load: () -> Void) {
        guard isContentEmpty, !isLoading else { return }
        load()
    }

    func refresh(
        hasContent: Bool,
        priority: TaskPriority = .userInitiated,
        performLoad: @escaping (Bool, Bool) async -> Void
    ) async {
        if let task = activeTask {
            await task.value
            return
        }

        let task = beginLoad(priority: priority) {
            await performLoad(true, !hasContent)
        }
        await task.value
    }

    func load(
        priority: TaskPriority = .userInitiated,
        performLoad: @escaping (Bool, Bool) async -> Void
    ) {
        guard !isLoading else { return }
        _ = beginLoad(priority: priority) {
            await performLoad(false, true)
        }
    }

    @discardableResult
    func beginLoad(
        priority: TaskPriority = .userInitiated,
        operation: @escaping () async -> Void
    ) -> Task<Void, Never> {
        let task = Task(priority: priority) { await operation() }
        activeTask = task
        state = .loading(task)
        return task
    }

    // MARK: - State Management

    func markIdle() {
        activeTask = nil
        state = .idle
    }

    // MARK: - Cancellation

    func cancel() {
        activeTask?.cancel()
    }
}

// MARK: - HomeTabRootViewModel

@MainActor
final class HomeTabRootViewModel: ObservableObject {

    // MARK: - Properties

    let parentTab: JikanAPIRequestScope = .home

    private let coordinator: HomeFeedCoordinator
    private static let initialLoadGracePeriod: Duration = .milliseconds(600)

    // MARK: - Lifecycle

    init(coordinator: HomeFeedCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Tab Lifecycle

    func screenDidAppear() async {
        guard await coordinator.screenDidAppear() else { return }

        do {
            try await Task.sleep(for: Self.initialLoadGracePeriod)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        await coordinator.loadInitial()

        guard !Task.isCancelled else { return }

        let platform = UserInterfacePlatform.current
        if platform.shouldPreloadHomeDeferredSections {
            await coordinator.loadDeferredSections(
                priority: .utility,
                sectionDelay: platform.homeDeferredSectionLoadDelay
            )
        }
    }

    func screenDidDisappear() {
        coordinator.screenDidDisappear()
    }
}

extension HomeTabRootViewModel: TabScreenLifecyclePresentable {}
