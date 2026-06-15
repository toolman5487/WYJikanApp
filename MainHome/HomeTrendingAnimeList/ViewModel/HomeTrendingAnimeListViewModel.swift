//
//  HomeTrendingAnimeListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import Combine
import Foundation

@MainActor
final class HomeTrendingAnimeListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(HomeTrendingAnimeListContent)
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    @Published var selectedSort: HomeTrendingAnimeListSort = .apiDefault
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeTrendingAnimeListServicing
    private let presentationBuilder: HomeTrendingAnimeListPresentationBuilder
    private let pageSize = 12

    private var pagination = PaginatedListState<HomeTrendingAnimeListItem>()
    private var cancellables: Set<AnyCancellable> = []

    init(
        service: HomeTrendingAnimeListServicing,
        presentationBuilder: HomeTrendingAnimeListPresentationBuilder = HomeTrendingAnimeListPresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
        bindSelectedSort()
    }

    var headerContent: HomeTrendingAnimeListHeaderContent {
        presentationBuilder.headerContent(sort: selectedSort, loadedCount: pagination.items.count)
    }

    var sortChipItems: [HomeTrendingAnimeListSortChipItem] {
        HomeTrendingAnimeListSort.allCases.map { sort in
            HomeTrendingAnimeListSortChipItem(
                sort: sort,
                isSelected: selectedSort == sort
            )
        }
    }

    func loadIfNeeded() async {
        guard !pagination.hasLoaded else { return }
        await fetchFirstPage(showSkeleton: true)
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

    private func bindSelectedSort() {
        $selectedSort
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, self.pagination.hasLoaded else { return }
                self.applyPresentation()
            }
            .store(in: &cancellables)
    }

    private func fetchFirstPage(showSkeleton: Bool) async {
        let generation = pagination.beginReload(clearItems: showSkeleton)

        if showSkeleton {
            screenState = .loading
            loadMoreState = pagination.footerState
        }

        do {
            let response = try await service.fetchPage(page: 1, limit: pageSize)
            guard pagination.finishReload(
                PaginatedPage(
                    items: response.data.compactMap(presentationBuilder.item(from:)),
                    currentPage: response.pagination?.currentPage ?? 1,
                    hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
                ),
                generation: generation
            ) else { return }
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard pagination.isCurrent(generation) else { return }
            screenState = .error(FeatureLoadFailure(error))
            loadMoreState = .hidden
        }
    }

    private func loadMorePage() async {
        guard let generation = pagination.beginLoadMore() else { return }
        loadMoreState = pagination.footerState

        do {
            let response = try await service.fetchPage(page: pagination.currentPage + 1, limit: pageSize)
            guard pagination.finishLoadMore(
                PaginatedPage(
                    items: response.data.compactMap(presentationBuilder.item(from:)),
                    currentPage: response.pagination?.currentPage ?? pagination.currentPage + 1,
                    hasNextPage: response.pagination?.hasNextPage ?? !response.data.isEmpty
                ),
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

    private func applyPresentation() {
        guard !pagination.items.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        let rankedItems = presentationBuilder.sortedItems(pagination.items, sort: selectedSort)
        let sections = presentationBuilder.sections(from: rankedItems, sort: selectedSort)

        screenState = .content(
            HomeTrendingAnimeListContent(
                sections: sections
            )
        )
        loadMoreState = pagination.footerState
    }

}
