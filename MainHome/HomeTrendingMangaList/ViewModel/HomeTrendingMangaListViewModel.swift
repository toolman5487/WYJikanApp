//
//  HomeTrendingMangaListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import Combine
import Foundation

// MARK: - HomeTrendingMangaListViewModel

@MainActor
final class HomeTrendingMangaListViewModel: ObservableObject {

    // MARK: - Nested Types

    enum ScreenState {
        case loading
        case content(items: [MangaCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Properties

    @Published var selectedSort: HomeTrendingMangaListSort = .apiDefault
    @Published var selectedFormat: HomeTrendingMangaListFormat = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeTrendingMangaListServicing
    private let presentationBuilder: HomeTrendingMangaListPresentationBuilder
    private let pageSize = 24

    private let paginationController = PaginatedListLoadingController<MangaCategoryItemDTO>()
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle

    init(
        service: HomeTrendingMangaListServicing,
        presentationBuilder: HomeTrendingMangaListPresentationBuilder = HomeTrendingMangaListPresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
        bindPresentation()
    }

    // MARK: - Derived State

    var headerTitle: String {
        presentationBuilder.headerTitle(sort: selectedSort, format: selectedFormat)
    }

    var headerSubtitle: String {
        presentationBuilder.headerSubtitle(sort: selectedSort, format: selectedFormat)
    }

    var loadedCountText: String {
        "已載入 \(paginationController.items.count) 部"
    }

    // MARK: - Public Methods

    func loadIfNeeded() async {
        await paginationController.loadIfNeeded(
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    func reload() async {
        await fetchFirstPage(showSkeleton: true)
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func loadMoreIfNeeded(currentItem item: MangaCategoryItemDTO) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    // MARK: - Private Methods

    private func bindPresentation() {
        Publishers.CombineLatest(
            $selectedSort.removeDuplicates(),
            $selectedFormat.removeDuplicates()
        )
            .dropFirst()
            .sink { [weak self] _, _ in
                guard let self, self.paginationController.hasLoaded else { return }
                self.applyPresentation(
                    items: self.paginationController.items,
                    footerState: self.paginationController.footerState
                )
            }
            .store(in: &cancellables)
    }

    private func fetchFirstPage(showSkeleton: Bool) async {
        await paginationController.reload(
            showSkeleton: showSkeleton,
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    private func loadMorePage() async {
        await paginationController.loadMore(
            requiresNewItemsForNextPage: true,
            fetchPage: fetchPage,
            setFooterState: applyFooterState,
            applyPresentation: applyPresentation
        )
    }

    private func fetchPage(_ page: Int) async throws -> PaginatedPage<MangaCategoryItemDTO> {
        let trendingPage = try await service.fetchPage(page: page, limit: pageSize)
        return PaginatedPage(
            items: trendingPage.items,
            currentPage: trendingPage.currentPage,
            hasNextPage: trendingPage.hasNextPage
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

    private func applyPresentation(items: [MangaCategoryItemDTO], footerState: PaginationFooterState) {
        guard !items.isEmpty else {
            screenState = .empty
            loadMoreState = footerState
            return
        }

        let presentedItems = presentationBuilder.presentedItems(
            from: items,
            sort: selectedSort,
            format: selectedFormat
        )
        screenState = presentedItems.isEmpty ? .empty : .content(items: presentedItems)
        loadMoreState = footerState
    }

    private func shouldLoadMore(after item: MangaCategoryItemDTO) -> Bool {
        let visibleItems = visibleItemsForPagination()
        return paginationController.shouldLoadMore(after: item, visibleItems: visibleItems)
    }

    private func visibleItemsForPagination() -> [MangaCategoryItemDTO] {
        switch screenState {
        case .content(let items):
            return items
        case .loading, .empty, .error:
            return presentationBuilder.presentedItems(
                from: paginationController.items,
                sort: selectedSort,
                format: selectedFormat
            )
        }
    }
}
