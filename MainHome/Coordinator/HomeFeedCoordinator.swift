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
    func loadIfNeeded()
    func refresh() async
}

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
    private var loadedSections = Set<HomeFeedSection>()

    // MARK: - Lifecycle

    init(viewModels: HomeFeedViewModels) {
        self.viewModels = viewModels
    }

    // MARK: - Public Methods

    func loadInitial() async {
        await loadPhase(.heroBanner, .todayAnime)
        await loadPhase(.trendingAnime, .trendingManga)
    }

    func loadSectionIfNeeded(_ section: HomeFeedSection) async {
        guard section.isDeferred else { return }
        await load(section)
    }

    func refreshAll() async {
        await refreshPhase(.heroBanner, .todayAnime)
        await refreshPhase(.trendingAnime, .trendingManga)
        await refreshPhase(.watchPromos, .watchEpisodes)
        await refresh(.recommendedAnime)
    }

    // MARK: - Phase Loading

    private func loadPhase(_ first: HomeFeedSection, _ second: HomeFeedSection) async {
        async let firstLoad = load(first)
        async let secondLoad = load(second)
        _ = await (firstLoad, secondLoad)
    }

    private func refreshPhase(_ first: HomeFeedSection, _ second: HomeFeedSection) async {
        async let firstRefresh = refresh(first)
        async let secondRefresh = refresh(second)
        _ = await (firstRefresh, secondRefresh)
    }

    // MARK: - Section Operations

    private func load(_ section: HomeFeedSection) async {
        guard loadedSections.insert(section).inserted else { return }

        switch section {
        case .heroBanner:
            await loadIfNeeded(viewModels.heroBanner)
        case .todayAnime:
            await loadIfNeeded(viewModels.todayAnime)
        case .trendingAnime:
            await loadIfNeeded(viewModels.trendingAnime)
        case .trendingManga:
            await loadIfNeeded(viewModels.trendingManga)
        case .watchPromos:
            await loadIfNeeded(viewModels.watchPromos)
        case .watchEpisodes:
            await loadIfNeeded(viewModels.watchEpisodes)
        case .recommendedAnime:
            await loadIfNeeded(viewModels.recommendedAnime)
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

    private func loadIfNeeded(_ viewModel: some HomeFeedInitialLoadable) async {
        guard !viewModel.hasFeedContent else { return }
        viewModel.loadIfNeeded()
        await viewModel.refresh()
    }
}

// MARK: - HomeFeedSectionLoader

@MainActor
final class HomeFeedSectionLoader {
    enum State {
        case idle
        case loading(Task<Void, Never>)

        fileprivate var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    private(set) var state: State = .idle
    private nonisolated(unsafe) var activeTask: Task<Void, Never>?

    var isLoading: Bool { state.isLoading }

    var task: Task<Void, Never>? { activeTask }

    func loadIfNeeded(isContentEmpty: Bool, load: () -> Void) {
        guard isContentEmpty, !isLoading else { return }
        load()
    }

    func refresh(hasContent: Bool, performLoad: @escaping (Bool, Bool) async -> Void) async {
        if let task = activeTask {
            await task.value
            return
        }

        let task = beginLoad {
            await performLoad(true, !hasContent)
        }
        await task.value
    }

    func load(performLoad: @escaping (Bool, Bool) async -> Void) {
        guard !isLoading else { return }
        _ = beginLoad {
            await performLoad(false, true)
        }
    }

    @discardableResult
    func beginLoad(operation: @escaping () async -> Void) -> Task<Void, Never> {
        let task = Task { await operation() }
        activeTask = task
        state = .loading(task)
        return task
    }

    func markIdle() {
        activeTask = nil
        state = .idle
    }

    nonisolated func cancel() {
        activeTask?.cancel()
    }
}
