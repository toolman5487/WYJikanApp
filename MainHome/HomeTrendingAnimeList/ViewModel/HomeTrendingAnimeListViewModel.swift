//
//  HomeTrendingAnimeListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import Combine
import Foundation

// MARK: - HomeTrendingAnimeListViewModel

@MainActor
final class HomeTrendingAnimeListViewModel: ObservableObject {

    // MARK: - Nested Types

    enum ScreenState {
        case loading
        case content(HomeTrendingAnimeListContent)
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Properties

    @Published var selectedSort: HomeTrendingAnimeListSort = .apiDefault
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeTrendingAnimeListServicing
    private let presentationBuilder: HomeTrendingAnimeListPresentationBuilder
    private let requestLifecycleController: RequestScreenLifecycleController
    private let pageSize = 12

    private let paginationController = PaginatedListLoadingController<HomeTrendingAnimeListItem>()
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle

    init(
        service: HomeTrendingAnimeListServicing,
        requestLifecycleManager: any RequestLifecycleManaging,
        presentationBuilder: HomeTrendingAnimeListPresentationBuilder = HomeTrendingAnimeListPresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: .homeTrendingAnimeList,
            requestLifecycleManager: requestLifecycleManager
        )
        bindSelectedSort()
    }

    // MARK: - Derived State

    var headerContent: HomeTrendingAnimeListHeaderContent {
        presentationBuilder.headerContent(sort: selectedSort, loadedCount: paginationController.items.count)
    }

    var sortChipItems: [HomeTrendingAnimeListSortChipItem] {
        HomeTrendingAnimeListSort.allCases.map { sort in
            HomeTrendingAnimeListSortChipItem(
                sort: sort,
                isSelected: selectedSort == sort
            )
        }
    }

    // MARK: - Public Methods

    func screenDidAppear() async {
        guard await requestLifecycleController.activate() else { return }
        await paginationController.loadIfNeeded(
            setLoading: applyLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyInitialLoadError
        )
    }

    func screenDidDisappear() {
        requestLifecycleController.deactivate()
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

    func selectSort(_ sort: HomeTrendingAnimeListSort) {
        guard selectedSort != sort else { return }
        selectedSort = sort
    }

    // MARK: - Private Methods

    private func bindSelectedSort() {
        $selectedSort
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
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

    private func fetchPage(_ page: Int) async throws -> PaginatedPage<HomeTrendingAnimeListItem> {
        let response = try await service.fetchPage(page: page, limit: pageSize)
        return PaginatedPage(
            items: response.data.compactMap(presentationBuilder.item(from:)),
            currentPage: response.pagination?.currentPage ?? page,
            hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
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

    private func applyPresentation(items: [HomeTrendingAnimeListItem], footerState: PaginationFooterState) {
        guard !items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        let rankedItems = presentationBuilder.sortedItems(items, sort: selectedSort)
        let sections = presentationBuilder.sections(from: rankedItems, sort: selectedSort)

        screenState = .content(
            HomeTrendingAnimeListContent(
                sections: sections
            )
        )
        loadMoreState = footerState
    }
}
