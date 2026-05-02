//
//  AnimeCategoryDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/2.
//

import Foundation
import Combine

@MainActor
final class AnimeCategoryDetailViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(items: [AnimeCategoryItemDTO])
        case empty
        case error(message: String)
    }

    enum LoadMoreState: Equatable {
        case hidden
        case available
        case loading
        case error(message: String)
    }

    // MARK: - Published State

    @Published var selectedSort: AnimeCategoryFilter.Sort = .default
    @Published var selectedFormat: AnimeCategoryFilter.Format = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    let genre: AnimeListGenreDTO

    private let service: AnimeCategoryDetailServicing

    // MARK: - Pagination State

    private let pageSize = 24
    private var hasLoaded = false
    private var currentPage = 0
    private var hasNextPage = false
    private var isLoadingMore = false
    private var sourceItems: [AnimeCategoryItemDTO] = []
    private var requestGeneration = 0
    private var cancellables: Set<AnyCancellable> = []
    private var filterRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        genre: AnimeListGenreDTO,
        service: AnimeCategoryDetailServicing = AnimeCategoryDetailService()
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
        "已載入 \(sourceItems.count) 部"
    }

    // MARK: - Public Methods

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
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

    func loadMoreIfNeeded(currentItem item: AnimeCategoryItemDTO) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    // MARK: - Filter Binding

    private var currentFilter: AnimeCategoryFilter {
        AnimeCategoryFilter(sort: selectedSort, format: selectedFormat)
    }

    private func bindPresentation() {
        Publishers.CombineLatest(
            $selectedSort.removeDuplicates(),
            $selectedFormat.removeDuplicates()
        )
        .dropFirst()
        .sink { [weak self] _, _ in
            guard let self, self.hasLoaded else { return }
            self.filterRequestTask?.cancel()
            self.filterRequestTask = Task { [weak self] in
                guard let self else { return }
                await self.fetchFirstPage(showSkeleton: true)
            }
        }
        .store(in: &cancellables)
    }

    // MARK: - Loading

    private func resetPagination() {
        currentPage = 0
        hasNextPage = false
        isLoadingMore = false
        loadMoreState = .hidden
    }

    private func fetchFirstPage(showSkeleton: Bool) async {
        let generation = advanceRequestGeneration()
        resetPagination()
        filterRequestTask = nil
        if showSkeleton {
            sourceItems = []
            screenState = .loading
        }

        do {
            let page = try await service.fetchInitialPage(
                genreId: genre.id,
                pageSize: pageSize,
                filter: currentFilter
            )
            guard isCurrentGeneration(generation) else { return }
            hasLoaded = true
            currentPage = page.currentPage
            hasNextPage = page.hasNextPage
            sourceItems = deduplicatedItems(page.items)
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentGeneration(generation) else { return }
            screenState = .error(message: error.localizedDescription)
            loadMoreState = .hidden
        }
    }

    private func loadMorePage() async {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return }
        let generation = requestGeneration
        isLoadingMore = true
        loadMoreState = .loading
        defer {
            if isCurrentGeneration(generation) {
                isLoadingMore = false
            }
        }

        do {
            let page = try await service.fetchPage(
                genreId: genre.id,
                page: currentPage + 1,
                pageSize: pageSize,
                filter: currentFilter
            )
            guard isCurrentGeneration(generation) else { return }
            currentPage = page.currentPage
            hasNextPage = page.hasNextPage
            sourceItems = mergedDeduplicatedItems(
                existing: sourceItems,
                incoming: page.items
            )
            applyPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentGeneration(generation) else { return }
            loadMoreState = .error(message: "載入更多失敗")
        }
    }

    private func applyPresentation() {
        guard !sourceItems.isEmpty else {
            screenState = .empty
            loadMoreState = .hidden
            return
        }

        screenState = .content(items: sourceItems)
        loadMoreState = resolvedLoadMoreState()
    }

    private func shouldLoadMore(after item: AnimeCategoryItemDTO) -> Bool {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return false }
        guard case .content(let items) = screenState else { return false }
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return false }
        return index >= max(items.count - 5, 0)
    }

    private func resolvedLoadMoreState() -> LoadMoreState {
        if isLoadingMore {
            return .loading
        }
        if case .error(let message) = loadMoreState {
            return .error(message: message)
        }
        return hasNextPage ? .available : .hidden
    }

    private func advanceRequestGeneration() -> Int {
        requestGeneration += 1
        return requestGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        generation == requestGeneration
    }

    private func deduplicatedItems(_ items: [AnimeCategoryItemDTO]) -> [AnimeCategoryItemDTO] {
        var seenIDs: Set<Int> = []
        return items.filter { item in
            seenIDs.insert(item.id).inserted
        }
    }

    private func mergedDeduplicatedItems(
        existing: [AnimeCategoryItemDTO],
        incoming: [AnimeCategoryItemDTO]
    ) -> [AnimeCategoryItemDTO] {
        deduplicatedItems(existing + incoming)
    }
}
