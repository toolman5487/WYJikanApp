//
//  HomeWatchListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Combine
import Foundation

@MainActor
final class HomeWatchListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content([HomeWatchListItem])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    @Published private(set) var selectedFeed: HomeWatchFeedKind
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeWatchServicing
    private let pageSize = 12
    private var pagination = PaginatedListState<HomeWatchListItem>()
    private var feedChangeTask: Task<Void, Never>?

    init(
        initialFeed: HomeWatchFeedKind = .latestEpisodes,
        service: HomeWatchServicing
    ) {
        self.selectedFeed = initialFeed
        self.service = service
    }

    deinit {
        feedChangeTask?.cancel()
    }

    var headerContent: HomeWatchListHeaderContent {
        HomeWatchListHeaderContent(
            title: selectedFeed.title,
            subtitle: selectedFeed.subtitle,
            loadedCountText: "已載入 \(pagination.items.count) 筆"
        )
    }

    var feedChipItems: [HomeWatchFeedChipItem] {
        HomeWatchFeedKind.allCases.map { feed in
            HomeWatchFeedChipItem(
                feed: feed,
                isSelected: selectedFeed == feed
            )
        }
    }

    func loadIfNeeded() async {
        guard !pagination.hasLoaded else { return }
        await fetchFirstPage(showSkeleton: true, forceRefresh: false)
    }

    func reload() async {
        await fetchFirstPage(showSkeleton: true, forceRefresh: true)
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func selectFeed(_ feed: HomeWatchFeedKind) {
        guard selectedFeed != feed else { return }
        selectedFeed = feed
        feedChangeTask?.cancel()
        feedChangeTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchFirstPage(showSkeleton: true, forceRefresh: false)
        }
    }

    private func fetchFirstPage(showSkeleton: Bool, forceRefresh: Bool) async {
        let feed = selectedFeed
        let generation = pagination.beginReload(clearItems: showSkeleton)

        if showSkeleton {
            screenState = .loading
            loadMoreState = pagination.footerState
        }

        do {
            let page = try await fetchPage(feed: feed, page: 1, forceRefresh: forceRefresh)
            guard selectedFeed == feed,
                  pagination.finishReload(page, generation: generation) else { return }
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard selectedFeed == feed,
                  pagination.isCurrent(generation) else { return }
            screenState = .error(FeatureLoadFailure(error))
            loadMoreState = .hidden
        }
    }

    private func loadMorePage() async {
        let feed = selectedFeed
        guard let generation = pagination.beginLoadMore() else { return }
        loadMoreState = pagination.footerState

        do {
            let page = try await fetchPage(feed: feed, page: pagination.currentPage + 1, forceRefresh: false)
            guard selectedFeed == feed,
                  pagination.finishLoadMore(
                page,
                generation: generation,
                requiresNewItemsForNextPage: true
            ) else { return }
            applyPresentation()
        } catch is CancellationError {
            if pagination.cancelLoadMore(generation: generation) {
                loadMoreState = pagination.footerState
            }
            return
        } catch {
            guard pagination.failLoadMore(FeatureLoadFailure.loadMore(), generation: generation) else { return }
            loadMoreState = pagination.footerState
        }
    }

    private func fetchPage(
        feed: HomeWatchFeedKind,
        page: Int,
        forceRefresh: Bool
    ) async throws -> PaginatedPage<HomeWatchListItem> {
        if let episodeFeed = feed.episodeFeed {
            let response = try await service.fetchEpisodes(
                feed: episodeFeed,
                page: page,
                limit: pageSize,
                forceRefresh: forceRefresh
            )
            let items = HomeWatchPresentationBuilder.listItems(from: response, feed: feed)
            return PaginatedPage(
                items: items,
                currentPage: response.pagination?.currentPage ?? page,
                hasNextPage: response.pagination?.hasNextPage ?? !items.isEmpty
            )
        }

        guard let promoFeed = feed.promoFeed else {
            return PaginatedPage(items: [], currentPage: page, hasNextPage: false)
        }

        let response = try await service.fetchPromos(
            feed: promoFeed,
            page: page,
            limit: pageSize,
            forceRefresh: forceRefresh
        )
        let items = HomeWatchPresentationBuilder.listItems(from: response, feed: feed)
        return PaginatedPage(
            items: items,
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !items.isEmpty
        )
    }

    private func applyPresentation() {
        guard !pagination.items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        screenState = .content(pagination.items)
        loadMoreState = pagination.footerState
    }
}
