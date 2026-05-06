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
        case error(message: String)
    }

    enum LoadMoreState: Equatable {
        case hidden
        case available
        case loading
        case error(message: String)
    }

    @Published var selectedSort: HomeTrendingAnimeListSort = .apiDefault
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden
    @Published private(set) var isApplyingMenuSelection = false

    private let service: HomeTrendingAnimeListServicing
    private let pageSize = 25

    private var sourceItems: [HomeTrendingAnimeListItem] = []
    private var currentPage = 0
    private var hasNextPage = false
    private var hasLoaded = false
    private var isLoadingMore = false
    private var requestGeneration = 0
    private var cancellables: Set<AnyCancellable> = []
    private var menuSelectionTask: Task<Void, Never>?

    init(service: HomeTrendingAnimeListServicing = HomeTrendingAnimeListService()) {
        self.service = service
        bindSelectedSort()
    }

    var headerContent: HomeTrendingAnimeListHeaderContent {
        HomeTrendingAnimeListHeaderContent(
            title: "本週熱門動畫",
            subtitle: "整理現在最多人關注的動畫作品，先看榜首，再一路往下挖熱門清單。",
            loadedCountText: "已載入 \(sourceItems.count) 部"
        )
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

    func loadMoreIfNeeded(currentItem item: HomeTrendingAnimeListItem) async {
        guard shouldLoadMore(after: item) else { return }
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
                guard let self, self.hasLoaded else { return }
                self.presentSelectionChange()
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
            let response = try await service.fetchPage(page: 1, limit: pageSize)
            guard isCurrentGeneration(generation) else { return }

            hasLoaded = true
            currentPage = response.pagination?.currentPage ?? 1
            hasNextPage = response.pagination?.hasNextPage ?? !response.data.isEmpty
            sourceItems = deduplicatedItems(response.data.compactMap(Self.item(from:)))
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
            let response = try await service.fetchPage(page: currentPage + 1, limit: pageSize)
            guard isCurrentGeneration(generation) else { return }

            currentPage = response.pagination?.currentPage ?? currentPage + 1
            hasNextPage = response.pagination?.hasNextPage ?? !response.data.isEmpty

            let incoming = response.data.compactMap(Self.item(from:))
            sourceItems = mergedDeduplicatedItems(existing: sourceItems, incoming: incoming)
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

        let rankedItems = sortedItems(from: sourceItems)

        let featured = Array(rankedItems.prefix(3))
        let remaining = Array(rankedItems.dropFirst(3))
        let featuredSection = featured.isEmpty
            ? nil
            : HomeTrendingAnimeListFeaturedSectionContent(
                title: featuredSectionTitle(for: selectedSort),
                items: featured
            )
        let rankedSection = HomeTrendingAnimeListRankedSectionContent(
            title: rankedSectionTitle(for: selectedSort),
            countText: "\(remaining.count) 部",
            items: remaining
        )

        screenState = .content(
            HomeTrendingAnimeListContent(
                featuredSection: featuredSection,
                rankedSection: rankedSection
            )
        )
        loadMoreState = resolvedLoadMoreState()
    }

    private func presentSelectionChange() {
        menuSelectionTask?.cancel()
        menuSelectionTask = Task { [weak self] in
            guard let self else { return }

            isApplyingMenuSelection = true

            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            applyPresentation()
            isApplyingMenuSelection = false
        }
    }

    private func resetPagination() {
        currentPage = 0
        hasNextPage = false
        isLoadingMore = false
        loadMoreState = .hidden
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

    private func shouldLoadMore(after item: HomeTrendingAnimeListItem) -> Bool {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return false }
        let visibleItems = visibleItemsForPagination()
        guard let index = visibleItems.firstIndex(where: { $0.id == item.id }) else { return false }
        return index >= max(visibleItems.count - 5, 0)
    }

    private func advanceRequestGeneration() -> Int {
        requestGeneration += 1
        return requestGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        generation == requestGeneration
    }

    private func deduplicatedItems(_ items: [HomeTrendingAnimeListItem]) -> [HomeTrendingAnimeListItem] {
        var seenIDs: Set<Int> = []
        return items.filter { item in
            seenIDs.insert(item.id).inserted
        }
    }

    private func mergedDeduplicatedItems(
        existing: [HomeTrendingAnimeListItem],
        incoming: [HomeTrendingAnimeListItem]
    ) -> [HomeTrendingAnimeListItem] {
        deduplicatedItems(existing + incoming)
    }

    private func visibleItemsForPagination() -> [HomeTrendingAnimeListItem] {
        switch screenState {
        case .content(let content):
            return (content.featuredSection?.items ?? []) + content.rankedSection.items
        case .loading, .empty, .error:
            return sourceItems
        }
    }

    private func featuredSectionTitle(for sort: HomeTrendingAnimeListSort) -> String {
        switch sort {
        case .apiDefault, .rank:
            return "榜單焦點"
        case .popularity:
            return "人氣焦點"
        case .score:
            return "高分焦點"
        }
    }

    private func rankedSectionTitle(for sort: HomeTrendingAnimeListSort) -> String {
        switch sort {
        case .apiDefault:
            return "完整榜單"
        case .rank:
            return "排名整理"
        case .popularity:
            return "人氣整理"
        case .score:
            return "高分整理"
        }
    }

    private func sortedItems(from items: [HomeTrendingAnimeListItem]) -> [HomeTrendingAnimeListItem] {
        switch selectedSort {
        case .apiDefault:
            return items
        case .rank:
            return items.sorted { lhs, rhs in
                compareOptionalAscending(lhs.rank, rhs.rank, fallbackTitleLeft: lhs.title, fallbackTitleRight: rhs.title)
            }
        case .popularity:
            return items.sorted { lhs, rhs in
                let lhsValue = popularityValue(from: lhs.popularityText)
                let rhsValue = popularityValue(from: rhs.popularityText)
                return compareOptionalAscending(lhsValue, rhsValue, fallbackTitleLeft: lhs.title, fallbackTitleRight: rhs.title)
            }
        case .score:
            return items.sorted { lhs, rhs in
                let lhsValue = Double(lhs.scoreText ?? "")
                let rhsValue = Double(rhs.scoreText ?? "")
                return compareOptionalDescending(lhsValue, rhsValue, fallbackTitleLeft: lhs.title, fallbackTitleRight: rhs.title)
            }
        }
    }

    private func compareOptionalAscending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        fallbackTitleLeft: String,
        fallbackTitleRight: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (l?, r?):
            if l == r { return fallbackTitleLeft < fallbackTitleRight }
            return l < r
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
        case let (l?, r?):
            if l == r { return fallbackTitleLeft < fallbackTitleRight }
            return l > r
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return fallbackTitleLeft < fallbackTitleRight
        }
    }

    private func popularityValue(from text: String?) -> Int? {
        guard let text else { return nil }
        return Int(text.replacingOccurrences(of: "人氣 #", with: ""))
    }

    private static func item(from dto: HomeTrendingAnimeListDTO) -> HomeTrendingAnimeListItem? {
        HomeTrendingAnimeListItem(
            id: dto.id,
            title: displayTitle(
                japanese: dto.titleJapanese,
                english: dto.titleEnglish,
                fallback: dto.title
            ),
            typeText: typeDisplayText(dto.type),
            scoreText: scoreDisplayText(dto.score),
            rank: dto.rank,
            popularityText: dto.popularity.map { "人氣 #\($0)" },
            membersText: membersDisplayText(dto.members),
            episodeText: dto.episodes.map { "\($0) 集" },
            statusText: statusDisplayText(dto.status),
            seasonText: seasonDisplayText(season: dto.season, year: dto.year),
            synopsisPreview: synopsisPreview(dto.synopsis),
            imageURL: posterURL(from: dto)
        )
    }

    private static func displayTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let japanese, !japanese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return japanese
        }
        if let english, !english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return english
        }
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback
        }
        return "未命名作品"
    }

    private static func posterURL(from dto: HomeTrendingAnimeListDTO) -> URL? {
        let raw =
            dto.images?.webp?.largeImageUrl ??
            dto.images?.jpg?.largeImageUrl ??
            dto.images?.webp?.imageUrl ??
            dto.images?.jpg?.imageUrl

        guard let raw else { return nil }
        return URL(string: raw)
    }

    private static func typeDisplayText(_ raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        switch raw.uppercased() {
        case "TV": return "電視動畫"
        case "MOVIE": return "劇場版"
        case "OVA": return "OVA"
        case "ONA": return "ONA"
        case "SPECIAL": return "特別篇"
        case "MUSIC": return "音樂"
        default: return raw
        }
    }

    private static func scoreDisplayText(_ score: Double?) -> String? {
        guard let score else { return nil }
        return String(format: "%.2f", score)
    }

    private static func membersDisplayText(_ members: Int?) -> String? {
        guard let members else { return nil }
        if members >= 1_000_000 {
            return String(format: "%.1fM 收藏", Double(members) / 1_000_000)
        }
        if members >= 1_000 {
            return String(format: "%.1fK 收藏", Double(members) / 1_000)
        }
        return "\(members) 收藏"
    }

    private static func statusDisplayText(_ raw: String?) -> String? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        switch raw.lowercased() {
        case "currently airing": return "播出中"
        case "finished airing": return "已完結"
        case "not yet aired": return "尚未播出"
        default: return raw
        }
    }

    private static func seasonDisplayText(season: String?, year: Int?) -> String? {
        let seasonText: String?
        switch season?.lowercased() {
        case "winter": seasonText = "冬"
        case "spring": seasonText = "春"
        case "summer": seasonText = "夏"
        case "fall": seasonText = "秋"
        default: seasonText = nil
        }

        switch (seasonText, year) {
        case let (seasonText?, year?):
            return "\(year) \(seasonText)季"
        case let (seasonText?, nil):
            return seasonText
        case let (nil, year?):
            return "\(year)"
        case (nil, nil):
            return nil
        }
    }

    private static func synopsisPreview(_ synopsis: String?) -> String? {
        guard let synopsis else { return nil }
        let trimmed = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let limit = 110
        if trimmed.count <= limit {
            return trimmed
        }

        let index = trimmed.index(trimmed.startIndex, offsetBy: limit)
        return String(trimmed[..<index]) + "..."
    }
}
