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

    @Published private(set) var screenState: HomeRecommendedAnimeScreenState = .loading
    @Published private(set) var visibleCount: Int = 9

    private let service: MainHomeServicing
    private let presentationBuilder: HomeRecommendedAnimePresentationBuilder
    private let sectionLoader = HomeFeedSectionLoader()

    // MARK: - Lifecycle

    init(
        service: MainHomeServicing,
        presentationBuilder: HomeRecommendedAnimePresentationBuilder = HomeRecommendedAnimePresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
    }

    isolated deinit {
        sectionLoader.cancel()
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
        visibleCount = min(visibleCount + Self.loadMoreStep, allItems.count)
    }

    // MARK: - Private Methods

    private func performLoad(forceRefresh: Bool, showsLoadingState: Bool) async {
        let previousState = screenState
        let previousVisibleCount = visibleCount
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
            let items = presentationBuilder.cardItems(from: response.data)
            visibleCount = resolvedVisibleCount(
                itemCount: items.count,
                previousVisibleCount: previousVisibleCount,
                preservesExpandedState: forceRefresh && previousState.hasContent
            )
            screenState = items.isEmpty ? .empty : .content(items)
        } catch is CancellationError {
            return
        } catch {
            if forceRefresh, previousState.hasContent {
                screenState = previousState
                visibleCount = previousVisibleCount
            } else {
                screenState = .error(FeatureLoadFailure(error))
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
}
