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
        case error(message: String)
    }

    typealias LoadMoreState = MangaCategoryDetailViewModel.LoadMoreState

    @Published var selectedSort: HomeTrendingMangaListSort = .apiDefault
    @Published var selectedFormat: HomeTrendingMangaListFormat = .all
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    private let service: HomeTrendingMangaListServicing
    private let pageSize = 24

    private var sourceItems: [MangaCategoryItemDTO] = []
    private var currentPage = 0
    private var hasNextPage = false
    private var hasLoaded = false
    private var isLoadingMore = false
    private var requestGeneration = 0
    private var cancellables: Set<AnyCancellable> = []

    init(service: HomeTrendingMangaListServicing = HomeTrendingMangaListService()) {
        self.service = service
        bindPresentation()
    }

    var headerTitle: String {
        headerTitle(sort: selectedSort, format: selectedFormat)
    }

    var headerSubtitle: String {
        headerSubtitle(sort: selectedSort, format: selectedFormat)
    }

    var loadedCountText: String {
        "已載入 \(sourceItems.count) 部"
    }

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
                guard let self, self.hasLoaded else { return }
                self.applyPresentation()
            }
            .store(in: &cancellables)
    }

    private func fetchFirstPage(showSkeleton: Bool) async {
        let generation = advanceRequestGeneration()
        resetPagination()

        if showSkeleton {
            sourceItems = []
            screenState = .loading
        }

        do {
            let page = try await service.fetchPage(page: 1, limit: pageSize)
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

        do {
            let page = try await service.fetchPage(page: currentPage + 1, limit: pageSize)
            guard isCurrentGeneration(generation) else { return }

            currentPage = page.currentPage
            let mergedItems = mergedDeduplicatedItems(existing: sourceItems, incoming: page.items)
            let appendedNewItems = mergedItems.count > sourceItems.count

            hasNextPage = appendedNewItems && page.hasNextPage
            sourceItems = mergedItems
            isLoadingMore = false
            applyPresentation()
        } catch is CancellationError {
            if isCurrentGeneration(generation) {
                isLoadingMore = false
            }
            return
        } catch {
            guard isCurrentGeneration(generation) else { return }
            isLoadingMore = false
            loadMoreState = .error(message: "載入更多失敗")
        }
    }

    private func applyPresentation() {
        guard !sourceItems.isEmpty else {
            screenState = .empty
            loadMoreState = resolvedLoadMoreState()
            return
        }

        let presentedItems = presentedItems(from: sourceItems)
        screenState = presentedItems.isEmpty ? .empty : .content(items: presentedItems)
        loadMoreState = resolvedLoadMoreState()
    }

    private func presentedItems(from items: [MangaCategoryItemDTO]) -> [MangaCategoryItemDTO] {
        let filtered = items.filter { item in
            selectedFormat.matches(type: item.type)
        }

        switch selectedSort {
        case .apiDefault:
            return filtered
        case .rank:
            return filtered.sorted { lhs, rhs in
                compareOptionalAscending(
                    lhs.rank,
                    rhs.rank,
                    fallbackTitleLeft: lhs.displayTitle,
                    fallbackTitleRight: rhs.displayTitle
                )
            }
        case .popularity:
            return filtered.sorted { lhs, rhs in
                compareOptionalAscending(
                    lhs.popularity,
                    rhs.popularity,
                    fallbackTitleLeft: lhs.displayTitle,
                    fallbackTitleRight: rhs.displayTitle
                )
            }
        case .score:
            return filtered.sorted { lhs, rhs in
                compareOptionalDescending(
                    lhs.score,
                    rhs.score,
                    fallbackTitleLeft: lhs.displayTitle,
                    fallbackTitleRight: rhs.displayTitle
                )
            }
        }
    }

    private func shouldLoadMore(after item: MangaCategoryItemDTO) -> Bool {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return false }
        let visibleItems = visibleItemsForPagination()
        guard let index = visibleItems.firstIndex(where: { $0.id == item.id }) else { return false }
        return index >= max(visibleItems.count - 5, 0)
    }

    private func visibleItemsForPagination() -> [MangaCategoryItemDTO] {
        switch screenState {
        case .content(let items):
            return items
        case .loading, .empty, .error:
            return presentedItems(from: sourceItems)
        }
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

    private func headerTitle(sort: HomeTrendingMangaListSort, format: HomeTrendingMangaListFormat) -> String {
        let baseTitle: String
        switch sort {
        case .apiDefault:
            baseTitle = "本週熱門漫畫"
        case .rank:
            baseTitle = "排名漫畫榜"
        case .popularity:
            baseTitle = "人氣漫畫榜"
        case .score:
            baseTitle = "高分漫畫榜"
        }

        switch format {
        case .all:
            return baseTitle
        default:
            return "\(format.title)\(baseTitle)"
        }
    }

    private func headerSubtitle(sort: HomeTrendingMangaListSort, format: HomeTrendingMangaListFormat) -> String {
        switch (sort, format) {
        case (.apiDefault, .all):
            return "把現在榜上最受關注的漫畫一次展開，先看榜首，再慢慢往下挖完整熱門清單。"
        case (.rank, .all):
            return "從榜單名次一路往下看，先鎖定站上前段班、討論度高的漫畫作品。"
        case (.popularity, .all):
            return "依人氣熱度重新整理，適合先找現在最多人追、最常被提起的熱門作品。"
        case (.score, .all):
            return "把評價表現突出的作品拉到前面，想先看口碑穩、分數亮眼的漫畫可以從這裡開始。"
        case (.apiDefault, _):
            return "整理目前最受關注的\(format.title)作品，讓你快速找到這個類型裡最值得先看的熱門選擇。"
        case (.rank, _):
            return "從名次往下看這批\(format.title)作品，先鎖定榜上前段班與討論度高的焦點名單。"
        case (.popularity, _):
            return "依人氣熱度重新整理這批\(format.title)作品，適合先找現在最多人追的熱門選擇。"
        case (.score, _):
            return "把高評價的\(format.title)作品拉到前面，想先看口碑穩、分數亮眼的類型可以從這裡開始。"
        }
    }

    private func resetPagination() {
        currentPage = 0
        hasNextPage = false
        isLoadingMore = false
        loadMoreState = .hidden
    }

    private func advanceRequestGeneration() -> Int {
        requestGeneration += 1
        return requestGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        generation == requestGeneration
    }

    private func deduplicatedItems(_ items: [MangaCategoryItemDTO]) -> [MangaCategoryItemDTO] {
        var seenIDs: Set<Int> = []
        return items.filter { item in
            seenIDs.insert(item.id).inserted
        }
    }

    private func mergedDeduplicatedItems(
        existing: [MangaCategoryItemDTO],
        incoming: [MangaCategoryItemDTO]
    ) -> [MangaCategoryItemDTO] {
        deduplicatedItems(existing + incoming)
    }

    private func compareOptionalAscending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        fallbackTitleLeft: String,
        fallbackTitleRight: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs == rhs { return fallbackTitleLeft < fallbackTitleRight }
            return lhs < rhs
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return fallbackTitleLeft < fallbackTitleRight
        }
    }

    private func compareOptionalDescending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        fallbackTitleLeft: String,
        fallbackTitleRight: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            if lhs == rhs { return fallbackTitleLeft < fallbackTitleRight }
            return lhs > rhs
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return fallbackTitleLeft < fallbackTitleRight
        }
    }
}
