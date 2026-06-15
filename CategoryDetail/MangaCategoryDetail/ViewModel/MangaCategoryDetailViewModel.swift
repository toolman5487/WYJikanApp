//
//  MangaCategoryDetailViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation
import Combine

@MainActor
final class MangaCategoryDetailViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(items: [MangaCategoryItemDTO])
        case empty
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Published State

    @Published var selectedSort: MangaCategoryFilter.Sort = .defaultSort
    @Published var selectedFormat: MangaCategoryFilter.Format = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    let genre: MangaListGenreDTO

    private let service: MangaCategoryDetailServicing

    // MARK: - Pagination State

    private let pageSize = 24
    private var pagination = PaginatedListState<MangaCategoryItemDTO>()
    private var cancellables: Set<AnyCancellable> = []
    private var filterRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        genre: MangaListGenreDTO,
        service: MangaCategoryDetailServicing
    ) {
        self.genre = genre
        self.service = service
        bindPresentation()
    }

    // MARK: - Derived State

    var genreTitle: String {
        genre.name ?? "未分類"
    }

    var headerSubtitle: String {
        "\(genreTitle) 類作品集中頁面，會依你選擇的條件重新整理資料，往下完整探索。"
    }

    var loadedCountText: String {
        "已載入 \(pagination.items.count) 部"
    }

    // MARK: - Public Methods

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

    // MARK: - Filter Binding

    private var currentFilter: MangaCategoryFilter {
        MangaCategoryFilter(sort: selectedSort, format: selectedFormat)
    }

    private func bindPresentation() {
        Publishers.CombineLatest(
            $selectedSort.removeDuplicates(),
            $selectedFormat.removeDuplicates()
        )
        .dropFirst()
        .sink { [weak self] _, _ in
            guard let self, self.pagination.hasLoaded else { return }
            self.filterRequestTask?.cancel()
            self.filterRequestTask = Task { [weak self] in
                guard let self else { return }
                await self.fetchFirstPage(showSkeleton: true)
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Loading

    private func fetchFirstPage(showSkeleton: Bool) async {
        let generation = pagination.beginReload(clearItems: showSkeleton)
        filterRequestTask = nil

        if showSkeleton {
            screenState = .loading
            loadMoreState = pagination.footerState
        }

        do {
            let page = try await service.fetchInitialPage(
                genreId: genre.id,
                pageSize: pageSize,
                filter: currentFilter
            )
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
            loadMoreState = pagination.footerState
        }
    }

    private func loadMorePage() async {
        guard let generation = pagination.beginLoadMore() else { return }
        loadMoreState = pagination.footerState

        do {
            let page = try await service.fetchPage(
                genreId: genre.id,
                page: pagination.currentPage + 1,
                pageSize: pageSize,
                filter: currentFilter
            )
            guard pagination.finishLoadMore(
                PaginatedPage(
                    items: page.items,
                    currentPage: page.currentPage,
                    hasNextPage: page.hasNextPage
                ),
                generation: generation
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

        screenState = .content(items: pagination.items)
        loadMoreState = pagination.footerState
    }

    private func shouldLoadMore(after item: MangaCategoryItemDTO) -> Bool {
        guard case .content(let items) = screenState else { return false }
        return pagination.shouldLoadMore(after: item, visibleItems: items)
    }
}
