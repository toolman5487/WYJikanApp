//
//  HomeWatchListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Combine
import Foundation

// MARK: - HomeWatchListViewModel

@MainActor
final class HomeWatchListViewModel: ObservableObject {

    // MARK: - Nested Types

    enum ScreenState {
        case loading
        case content([HomeWatchListItem])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Properties

    @Published private(set) var selectedFeed: HomeWatchFeedKind
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeWatchServicing
    private let requestLifecycleController: RequestScreenLifecycleController
    private let pageSize = 12
    private let paginationController = PaginatedListLoadingController<HomeWatchListItem>()
    private var feedChangeTask: Task<Void, Never>?

    let parentTab: JikanAPIRequestScope = .home

    // MARK: - Lifecycle

    init(
        initialFeed: HomeWatchFeedKind = .latestEpisodes,
        service: HomeWatchServicing,
        requestLifecycleController: any RequestLifecycleControlling
    ) {
        self.selectedFeed = initialFeed
        self.service = service
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: .homeWatchList,
            requestLifecycleController: requestLifecycleController
        )
    }

    deinit {
        feedChangeTask?.cancel()
    }

    // MARK: - Derived State

    var headerContent: HomeWatchListHeaderContent {
        HomeWatchListHeaderContent(
            title: selectedFeed.title,
            subtitle: selectedFeed.subtitle,
            loadedCountText: "已載入 \(paginationController.items.count) 筆"
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

    // MARK: - Public Methods

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        await performInitialLoadIfNeeded()
    }

    func screenDidDisappear() {
        stop()
        requestLifecycleController.deactivate()
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
        feedChangeTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.fetchFirstPage(showSkeleton: true, forceRefresh: false)
        }
    }

    // MARK: - Private Methods

    private func performInitialLoadIfNeeded() async {
        await paginationController.loadIfNeeded(
            setLoading: applyLoading,
            fetchPage: { [weak self] page in
                guard let self else {
                    return PaginatedPage(items: [], currentPage: page, hasNextPage: false)
                }
                return try await self.fetchPage(page: page, forceRefresh: false)
            },
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    private func fetchFirstPage(showSkeleton: Bool, forceRefresh: Bool) async {
        await paginationController.reload(
            showSkeleton: showSkeleton,
            setLoading: applyLoading,
            fetchPage: { [weak self] page in
                guard let self else {
                    return PaginatedPage(items: [], currentPage: page, hasNextPage: false)
                }
                return try await self.fetchPage(page: page, forceRefresh: forceRefresh)
            },
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    private func loadMorePage() async {
        await paginationController.loadMore(
            requiresNewItemsForNextPage: true,
            fetchPage: { [weak self] page in
                guard let self else {
                    return PaginatedPage(items: [], currentPage: page, hasNextPage: false)
                }
                return try await self.fetchPage(page: page, forceRefresh: false)
            },
            setFooterState: applyFooterState,
            applyPresentation: applyPresentation
        )
    }

    private func fetchPage(
        page: Int,
        forceRefresh: Bool
    ) async throws -> PaginatedPage<HomeWatchListItem> {
        let feed = selectedFeed
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

    private func applyLoading(footerState: PaginationFooterState) {
        screenState = .loading
        loadMoreState = footerState
    }

    private func applyInitialLoadError(_ failure: FeatureLoadFailure, footerState: PaginationFooterState) {
        screenState = .error(failure)
        loadMoreState = .hidden
    }

    private func applyFooterState(_ footerState: PaginationFooterState) {
        loadMoreState = footerState
    }

    private func applyPresentation(items: [HomeWatchListItem], footerState: PaginationFooterState) {
        guard !items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        screenState = .content(items)
        loadMoreState = footerState
    }
}

extension HomeWatchListViewModel: PaginatedListLoadControlling {
    var canLoadMore: Bool {
        paginationController.canLoadMore
    }

    var isLoadingMore: Bool {
        loadMoreState == .loading
    }

    func loadIfNeeded() {
        paginationController.run { [weak self] in
            await self?.performInitialLoadIfNeeded()
        }
    }

    func loadMore() {
        paginationController.run { [weak self] in
            await self?.loadMorePage()
        }
    }

    func reload() {
        paginationController.run { [weak self] in
            await self?.fetchFirstPage(showSkeleton: true, forceRefresh: true)
        }
    }

    func stop() {
        feedChangeTask?.cancel()
        feedChangeTask = nil
        paginationController.stopLoading()
    }
}

extension HomeWatchListViewModel: TabScreenLifecyclePresentable {}
