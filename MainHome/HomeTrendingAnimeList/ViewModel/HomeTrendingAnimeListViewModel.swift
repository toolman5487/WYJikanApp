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
    private let pageSize = 12

    private var pagination = PaginatedListState<HomeTrendingAnimeListItem>()
    private var cancellables: Set<AnyCancellable> = []

    init(service: HomeTrendingAnimeListServicing) {
        self.service = service
        bindSelectedSort()
    }

    var headerContent: HomeTrendingAnimeListHeaderContent {
        HomeTrendingAnimeListHeaderContent(
            title: headerTitle(for: selectedSort),
            subtitle: headerSubtitle(for: selectedSort),
            loadedCountText: "已載入 \(pagination.items.count) 部"
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
                    items: response.data.compactMap(Self.item(from:)),
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
                    items: response.data.compactMap(Self.item(from:)),
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

        let rankedItems = sortedItems(from: pagination.items)
        let sections = buildSections(from: rankedItems, sort: selectedSort)

        screenState = .content(
            HomeTrendingAnimeListContent(
                sections: sections
            )
        )
        loadMoreState = pagination.footerState
    }

    private func headerTitle(for sort: HomeTrendingAnimeListSort) -> String {
        switch sort {
        case .apiDefault:
            return "本週熱門動畫"
        case .rank:
            return "排名動畫榜"
        case .popularity:
            return "人氣動畫榜"
        case .score:
            return "高分動畫榜"
        }
    }

    private func headerSubtitle(for sort: HomeTrendingAnimeListSort) -> String {
        switch sort {
        case .apiDefault:
            return "整理現在最多人關注的動畫作品，先看榜首，再一路往下挖熱門清單。"
        case .rank:
            return "從榜單名次一路往下看，先鎖定站上前段班、討論度最高的動畫作品。"
        case .popularity:
            return "依人氣熱度重新整理，適合先找現在最多人追、最常被提起的熱門作品。"
        case .score:
            return "把評價表現突出的作品拉到前面，想先看口碑穩、分數亮眼的動畫可以從這裡開始。"
        }
    }

    private func buildSections(
        from items: [HomeTrendingAnimeListItem],
        sort: HomeTrendingAnimeListSort
    ) -> [HomeTrendingAnimeListSectionContent] {
        let definitions = sectionDefinitions(for: sort)
        return definitions.compactMap { definition in
            let sectionItems = items[safe: definition.range]
            guard !sectionItems.isEmpty else { return nil }
            return HomeTrendingAnimeListSectionContent(
                id: definition.id,
                title: definition.title,
                subtitle: definition.subtitle,
                countText: "\(sectionItems.count) 部",
                items: sectionItems
            )
        }
    }

    private func sectionDefinitions(for sort: HomeTrendingAnimeListSort) -> [TrendingSectionDefinition] {
        _ = sort
        return [
            TrendingSectionDefinition(id: "top3", title: "TOP 3", subtitle: "", range: 0..<3),
            TrendingSectionDefinition(id: "top10", title: "TOP 10", subtitle: "", range: 3..<10),
            TrendingSectionDefinition(id: "top25", title: "TOP 25", subtitle: "", range: 10..<25),
            TrendingSectionDefinition(id: "top25plus", title: "TOP 25+", subtitle: "", range: 25..<Int.max)
        ]
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
        JikanImageURLResolver.url(from: dto.images, tier: .poster)
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

    private struct TrendingSectionDefinition {
        let id: String
        let title: String
        let subtitle: String
        let range: Range<Int>
    }
}

private extension Array {
    subscript(safe range: Range<Int>) -> [Element] {
        guard !isEmpty else { return [] }
        let lowerBound = Swift.max(0, range.lowerBound)
        let upperBound = Swift.min(count, range.upperBound)
        guard lowerBound < upperBound else { return [] }
        return Array(self[lowerBound..<upperBound])
    }
}
