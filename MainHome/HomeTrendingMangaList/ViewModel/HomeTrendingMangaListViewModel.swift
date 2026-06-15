//
//  HomeTrendingMangaListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import Combine
import Foundation

@MainActor
final class HomeTrendingMangaListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(items: [MangaCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    @Published var selectedSort: HomeTrendingMangaListSort = .apiDefault
    @Published var selectedFormat: HomeTrendingMangaListFormat = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeTrendingMangaListServicing
    private let presentationBuilder: HomeTrendingMangaListPresentationBuilder
    private let pageSize = 24

    private var pagination = PaginatedListState<MangaCategoryItemDTO>()
    private var cancellables: Set<AnyCancellable> = []

    init(
        service: HomeTrendingMangaListServicing,
        presentationBuilder: HomeTrendingMangaListPresentationBuilder = HomeTrendingMangaListPresentationBuilder()
    ) {
        self.service = service
        self.presentationBuilder = presentationBuilder
        bindPresentation()
    }

    var headerTitle: String {
        presentationBuilder.headerTitle(sort: selectedSort, format: selectedFormat)
    }

    var headerSubtitle: String {
        presentationBuilder.headerSubtitle(sort: selectedSort, format: selectedFormat)
    }

    var loadedCountText: String {
        "已載入 \(pagination.items.count) 部"
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

    func loadMoreIfNeeded(currentItem item: MangaCategoryItemDTO) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    private func bindPresentation() {
        Publishers.CombineLatest(
            $selectedSort.removeDuplicates(),
            $selectedFormat.removeDuplicates()
        )
            .dropFirst()
            .sink { [weak self] _, _ in
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
            let page = try await service.fetchPage(page: 1, limit: pageSize)
            guard pagination.finishReload(
                PaginatedPage(
                    items: page.items,
                    currentPage: page.currentPage,
                    hasNextPage: page.hasNextPage
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
            let page = try await service.fetchPage(page: pagination.currentPage + 1, limit: pageSize)
            guard pagination.finishLoadMore(
                PaginatedPage(
                    items: page.items,
                    currentPage: page.currentPage,
                    hasNextPage: page.hasNextPage
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
            loadMoreState = pagination.footerState
            return
        }

        let presentedItems = presentationBuilder.presentedItems(
            from: pagination.items,
            sort: selectedSort,
            format: selectedFormat
        )
        screenState = presentedItems.isEmpty ? .empty : .content(items: presentedItems)
        loadMoreState = pagination.footerState
    }

    private func shouldLoadMore(after item: MangaCategoryItemDTO) -> Bool {
        let visibleItems = visibleItemsForPagination()
        return pagination.shouldLoadMore(after: item, visibleItems: visibleItems)
    }

    private func visibleItemsForPagination() -> [MangaCategoryItemDTO] {
        switch screenState {
        case .content(let items):
            return items
        case .loading, .empty, .error:
            return presentationBuilder.presentedItems(
                from: pagination.items,
                sort: selectedSort,
                format: selectedFormat
            )
        }
    }
}
