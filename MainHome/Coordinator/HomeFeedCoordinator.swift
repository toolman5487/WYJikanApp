//
//  HomeFeedCoordinator.swift
//  WYJikanApp
//

import Foundation

// MARK: - HomeFeedSection

enum HomeFeedSection: Hashable, CaseIterable {
    case heroBanner
    case todayAnime
    case trendingAnime
    case trendingManga
    case watchPromos
    case watchEpisodes
    case recommendedAnime

    var isDeferred: Bool {
        switch self {
        case .heroBanner, .todayAnime, .trendingAnime, .trendingManga:
            return false
        case .watchPromos, .watchEpisodes, .recommendedAnime:
            return true
        }
    }
}

// MARK: - HomeLoadPhase

nonisolated enum HomeLoadPhase: Int, CaseIterable, Sendable {
    case initialFeeds
    case allFeeds
}

// MARK: - HomeLoadCoordinating

nonisolated protocol HomeLoadCoordinating: Sendable {
    func wait(for phase: HomeLoadPhase) async
    func markCompleted(_ phase: HomeLoadPhase) async
}

// MARK: - HomeLoadCoordinator

actor HomeLoadCoordinator: HomeLoadCoordinating {

    // MARK: - Properties

    static let shared = HomeLoadCoordinator()

    private var completedPhases = Set<HomeLoadPhase>()
    private var waiters: [HomeLoadPhase: [CheckedContinuation<Void, Never>]] = [:]

    // MARK: - Public Methods

    func wait(for phase: HomeLoadPhase) async {
        guard !completedPhases.contains(phase) else { return }

        await withCheckedContinuation { continuation in
            waiters[phase, default: []].append(continuation)
        }
    }

    func markCompleted(_ phase: HomeLoadPhase) {
        for completedPhase in HomeLoadPhase.allCases where completedPhase.rawValue <= phase.rawValue {
            complete(completedPhase)
        }
    }

    // MARK: - Private Methods

    private func complete(_ phase: HomeLoadPhase) {
        guard completedPhases.insert(phase).inserted else { return }

        let pendingWaiters = waiters.removeValue(forKey: phase) ?? []
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
    var hasFeedContent: Bool { get }
    func loadIfNeeded(priority: TaskPriority)
    func refresh() async
}

// MARK: - HomeFeedInitialLoadable Conformance

extension HeroBannerViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

extension HomeTodayAnimeViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

extension HomeTrendingAnimeViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

extension HomeTrendingMangaViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

extension HomeWatchPromosViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

extension HomeWatchEpisodesViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

extension HomeRecommendedAnimeViewModel: HomeFeedInitialLoadable {
    var hasFeedContent: Bool { screenState.hasContent }
}

// MARK: - HomeFeedCoordinator

@MainActor
final class HomeFeedCoordinator {

    // MARK: - Properties

    private let viewModels: HomeFeedViewModels
    private let homeLoadCoordinator: any HomeLoadCoordinating
    private let deferredSectionLoadScheduler = HomeDeferredSectionLoadScheduler()
    private var loadedSections = Set<HomeFeedSection>()
    private var pendingDeferredSections = Set<HomeFeedSection>()

    // MARK: - Lifecycle

    init(
        viewModels: HomeFeedViewModels,
        homeLoadCoordinator: any HomeLoadCoordinating = HomeLoadCoordinator.shared
    ) {
        self.viewModels = viewModels
        self.homeLoadCoordinator = homeLoadCoordinator
    }

    // MARK: - Public Methods

    func loadInitial() async {
        AppLaunchSignposter.beginHomeInitialLoad()
        defer {
            AppLaunchSignposter.endHomeInitialLoad()
        }

        await loadPhase(.heroBanner, .todayAnime, priority: .userInitiated)
        await loadPhase(.trendingAnime, .trendingManga, priority: .userInitiated)
        await homeLoadCoordinator.markCompleted(.initialFeeds)
    }

    func loadSectionIfNeeded(_ section: HomeFeedSection) async {
        guard section.isDeferred else { return }
        await homeLoadCoordinator.wait(for: .initialFeeds)
        guard !Task.isCancelled else { return }
        await loadDeferredSection(section, priority: .utility)
    }

    func loadDeferredSections(
        priority: TaskPriority,
        sectionDelay: Duration = .zero
    ) async {
        await loadDeferredSection(.watchPromos, priority: priority)

        if sectionDelay > .zero {
            try? await Task.sleep(for: sectionDelay)
        }

        await loadDeferredSection(.watchEpisodes, priority: priority)

        if sectionDelay > .zero {
            try? await Task.sleep(for: sectionDelay)
        }

        await loadDeferredSection(.recommendedAnime, priority: priority)
    }

    func refreshAll() async {
        await refreshPhase(.heroBanner, .todayAnime)
        await refreshPhase(.trendingAnime, .trendingManga)
        await refreshPhase(.watchPromos, .watchEpisodes)
        await refresh(.recommendedAnime)
    }

    // MARK: - Phase Loading

    private func loadPhase(
        _ first: HomeFeedSection,
        _ second: HomeFeedSection,
        priority: TaskPriority
    ) async {
        async let firstLoad = load(first, priority: priority)
        async let secondLoad = load(second, priority: priority)
        _ = await (firstLoad, secondLoad)
    }

    private func refreshPhase(_ first: HomeFeedSection, _ second: HomeFeedSection) async {
        async let firstRefresh = refresh(first)
        async let secondRefresh = refresh(second)
        _ = await (firstRefresh, secondRefresh)
    }

    // MARK: - Section Operations

    private func loadDeferredSection(
        _ section: HomeFeedSection,
        priority: TaskPriority
    ) async {
        guard section.isDeferred,
              !loadedSections.contains(section),
              pendingDeferredSections.insert(section).inserted else {
            return
        }
        defer {
            pendingDeferredSections.remove(section)
        }

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
        guard loadedSections.insert(section).inserted else { return }

        switch section {
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

        if loadedSections.count == HomeFeedSection.allCases.count {
            await homeLoadCoordinator.markCompleted(.allFeeds)
        }
    }

    private func refresh(_ section: HomeFeedSection) async {
        switch section {
        case .heroBanner:
            await viewModels.heroBanner.refresh()
        case .todayAnime:
            await viewModels.todayAnime.refresh()
        case .trendingAnime:
            await viewModels.trendingAnime.refresh()
        case .trendingManga:
            await viewModels.trendingManga.refresh()
        case .watchPromos:
            await viewModels.watchPromos.refresh()
        case .watchEpisodes:
            await viewModels.watchEpisodes.refresh()
        case .recommendedAnime:
            await viewModels.recommendedAnime.refresh()
        }
    }

    private func loadIfNeeded(
        _ viewModel: some HomeFeedInitialLoadable,
        priority: TaskPriority
    ) async {
        guard !viewModel.hasFeedContent else { return }
        viewModel.loadIfNeeded(priority: priority)
        await viewModel.refresh()
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
