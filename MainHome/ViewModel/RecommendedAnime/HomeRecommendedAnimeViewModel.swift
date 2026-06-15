//
//  HomeRecommendedAnimeViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/27.
//

import Combine
import Foundation

typealias HomeRecommendedAnimeScreenState = LoadableContentState<[HomeRecommendedAnimeCardItem]>

// MARK: - HomeRecommendedAnimeViewModel

@MainActor
final class HomeRecommendedAnimeViewModel: ObservableObject {

    // MARK: - Properties

    private static let initialVisibleCards = 9
    private static let loadMoreStep = 9
    private static let maxCards = 30
    private static let maxTitleEnrichmentsPerPass = 3
    private static let titleCacheLimit = 100

    @Published private(set) var screenState: HomeRecommendedAnimeScreenState = .loading
    @Published private(set) var visibleCount: Int = 9

    private let service: MainHomeServicing
    private let presentationBuilder: HomeRecommendedAnimePresentationBuilder
    private let titleEnricher: HomeRecommendedAnimeTitleEnricher
    private let sectionLoader = HomeFeedSectionLoader()
    private var titleCache = HomeRecommendedAnimeTitleCache()
    private var titleEnrichmentTask: Task<Void, Never>?

    // MARK: - Lifecycle

    init(
        service: MainHomeServicing,
        animeDetailService: AnimeDetailServicing,
        presentationBuilder: HomeRecommendedAnimePresentationBuilder = HomeRecommendedAnimePresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
        self.titleEnricher = HomeRecommendedAnimeTitleEnricher(service: animeDetailService)
    }

    deinit {
        sectionLoader.cancel()
        titleEnrichmentTask?.cancel()
    }

    // MARK: - Derived State

    private var allItems: [HomeRecommendedAnimeCardItem] {
        screenState.items
    }

    var displayedItems: [HomeRecommendedAnimeCardItem] {
        Array(allItems.prefix(visibleCount))
    }

    var canLoadMore: Bool {
        visibleCount < allItems.count
    }

    // MARK: - Public Methods

    func loadIfNeeded(priority: TaskPriority = .userInitiated) {
        sectionLoader.loadIfNeeded(isContentEmpty: allItems.isEmpty) {
            load(priority: priority)
        }
    }

    func refresh() async {
        await sectionLoader.refresh(hasContent: screenState.hasContent) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    func load(priority: TaskPriority = .userInitiated) {
        sectionLoader.load(priority: priority) { [weak self] forceRefresh, showsLoadingState in
            await self?.performLoad(forceRefresh: forceRefresh, showsLoadingState: showsLoadingState)
        }
    }

    func loadMore() {
        let previousCount = visibleCount
        visibleCount = min(visibleCount + Self.loadMoreStep, allItems.count)
        guard visibleCount > previousCount else { return }
        startTitleEnrichmentIfNeeded()
    }

    // MARK: - Private Methods

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        let previousVisibleCount = visibleCount
        titleEnrichmentTask?.cancel()
        defer {
            sectionLoader.markIdle()
        }

        if showsLoadingState {
            screenState = .loading
            visibleCount = Self.initialVisibleCards
        }

        do {
            let response = try await service.fetchRecommendedAnime(
                limit: Self.maxCards,
                forceRefresh: forceRefresh
            )
            let items = presentationBuilder.cardItems(
                from: response.data,
                titleCache: titleCache
            )
            visibleCount = resolvedVisibleCount(
                itemCount: items.count,
                previousVisibleCount: previousVisibleCount,
                preservesExpandedState: forceRefresh && previousState.hasContent
            )
            screenState = items.isEmpty ? .empty : .content(items)
            startTitleEnrichmentIfNeeded()
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, previousState.hasContent {
                screenState = previousState
                visibleCount = previousVisibleCount
                startTitleEnrichmentIfNeeded()
            } else {
                screenState = .error(FeatureLoadFailure(error))
            }
        }
    }

    private func startTitleEnrichmentIfNeeded() {
        titleEnrichmentTask?.cancel()
        let uncachedIDs = displayedItems.compactMap { item in
            titleCache.title(for: item.detailMalId) == nil ? item.detailMalId : nil
        }
        let idsToFetch = Array(uncachedIDs.prefix(Self.maxTitleEnrichmentsPerPass))
        guard !idsToFetch.isEmpty else { return }

        titleEnrichmentTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            let titles = await titleEnricher.enrichedTitles(for: idsToFetch)
            guard !Task.isCancelled, !titles.isEmpty else { return }

            applyEnrichedTitles(titles)

            if !Task.isCancelled {
                startTitleEnrichmentIfNeeded()
            }
        }
    }

    private func resolvedVisibleCount(
        itemCount: Int,
        previousVisibleCount: Int,
        preservesExpandedState: Bool
    ) -> Int {
        guard itemCount > 0 else { return 0 }

        if preservesExpandedState {
            return min(max(previousVisibleCount, Self.initialVisibleCards), itemCount)
        }

        return min(Self.initialVisibleCards, itemCount)
    }

    private func applyEnrichedTitles(_ titles: [Int: String]) {
        for (malId, title) in titles {
            titleCache = titleCache.storing(
                title,
                for: malId,
                limit: Self.titleCacheLimit
            )
        }

        let updatedItems = allItems.map { item in
            guard let title = titles[item.detailMalId] else { return item }
            return HomeRecommendedAnimeCardItem(
                id: item.id,
                sourceTitle: item.sourceTitle,
                recommendedTitle: title,
                username: item.username,
                detailMalId: item.detailMalId,
                imageURL: item.imageURL
            )
        }
        screenState = updatedItems.isEmpty ? .empty : .content(updatedItems)
    }
}
