//
//  HomeTodayAnimeScheduleListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/4.
//

import Combine
import Foundation

@MainActor
final class HomeTodayAnimeScheduleListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case content(sections: [HomeTodayAnimeTimeSection])
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

    @Published var selectedDay: HomeScheduleDay
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    private let service: HomeTodayAnimeScheduleListServicing

    // MARK: - Pagination State

    private let pageSize = 25
    private var sourceItems: [HomeTodayAnimeTimelineItem] = []
    private var currentPage = 0
    private var hasNextPage = false
    private var hasLoaded = false
    private var isLoadingMore = false
    private var requestGeneration = 0
    private var cancellables: Set<AnyCancellable> = []
    private var dayRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        initialDay: HomeScheduleDay = .current(),
        service: HomeTodayAnimeScheduleListServicing = HomeTodayAnimeScheduleListService()
    ) {
        self.selectedDay = initialDay
        self.service = service
        bindSelectedDay()
    }

    // MARK: - Derived State

    var headerTitle: String {
        selectedDay == .current() ? "今日播出" : "\(selectedDay.title)播出"
    }

    var headerSubtitle: String {
        "依播出時間整理本週 TV 動畫，點進作品可查看完整詳細資料。"
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

    func loadMoreIfNeeded(currentItem item: HomeTodayAnimeTimelineItem) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    // MARK: - Binding

    private func bindSelectedDay() {
        $selectedDay
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.dayRequestTask?.cancel()
                self.dayRequestTask = Task { [weak self] in
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
        dayRequestTask = nil
        if showSkeleton {
            sourceItems = []
            screenState = .loading
        }

        do {
            let response = try await service.fetchSchedulePage(
                day: selectedDay,
                page: 1,
                limit: pageSize
            )
            guard isCurrentGeneration(generation) else { return }
            hasLoaded = true
            currentPage = response.pagination?.currentPage ?? 1
            hasNextPage = response.pagination?.hasNextPage ?? !response.data.isEmpty
            sourceItems = deduplicatedItems(response.data.compactMap(Self.timelineItem(from:)))
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
            let response = try await service.fetchSchedulePage(
                day: selectedDay,
                page: currentPage + 1,
                limit: pageSize
            )
            guard isCurrentGeneration(generation) else { return }
            currentPage = response.pagination?.currentPage ?? currentPage + 1
            hasNextPage = response.pagination?.hasNextPage ?? !response.data.isEmpty
            let incoming = response.data.compactMap(Self.timelineItem(from:))
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

        screenState = .content(sections: groupedSections(from: sourceItems))
        loadMoreState = resolvedLoadMoreState()
    }

    private func shouldLoadMore(after item: HomeTodayAnimeTimelineItem) -> Bool {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return false }
        let visibleItems = visibleTimelineItems()
        guard let index = visibleItems.firstIndex(where: { $0.id == item.id }) else { return false }
        return index >= max(visibleItems.count - 5, 0)
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

    private func visibleTimelineItems() -> [HomeTodayAnimeTimelineItem] {
        switch screenState {
        case .content(let sections):
            return sections.flatMap(\.items)
        case .loading, .empty, .error:
            return sourceItems
        }
    }

    // MARK: - Presentation Mapping

    private static func timelineItem(from dto: HomeTodayAnimeDTO) -> HomeTodayAnimeTimelineItem? {
        let timeInfo = timeInfo(from: dto.broadcast)
        return HomeTodayAnimeTimelineItem(
            id: dto.id,
            title: displayTitle(
                japanese: dto.titleJapanese,
                english: dto.titleEnglish,
                fallback: dto.title
            ),
            typeText: typeDisplayText(dto.type),
            scoreText: scoreDisplayText(dto.score),
            episodeText: dto.episodes.map { "\($0) 集" },
            statusText: statusDisplayText(dto.status),
            studioText: studioDisplayText(dto.studios),
            synopsisPreview: synopsisPreview(dto.synopsis),
            imageURL: posterURL(from: dto),
            timeSectionTitle: timeInfo.sectionTitle,
            timeSortValue: timeInfo.sortValue,
            broadcastText: timeInfo.displayText
        )
    }

    private func groupedSections(from items: [HomeTodayAnimeTimelineItem]) -> [HomeTodayAnimeTimeSection] {
        let sortedItems = items.sorted {
            if $0.timeSortValue == $1.timeSortValue {
                return $0.title < $1.title
            }
            return $0.timeSortValue < $1.timeSortValue
        }

        let grouped = Dictionary(grouping: sortedItems, by: \.timeSectionTitle)
        let orderedTitles = sortedItems.map(\.timeSectionTitle).reduce(into: [String]()) { result, title in
            if !result.contains(title) {
                result.append(title)
            }
        }

        return orderedTitles.compactMap { title in
            guard let items = grouped[title] else { return nil }
            return HomeTodayAnimeTimeSection(title: title, items: items)
        }
    }

    private static func timeInfo(from broadcast: AnimeBroadcastDTO?) -> (
        sectionTitle: String,
        sortValue: Int,
        displayText: String
    ) {
        let rawTime = broadcast?.time?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let sortValue = sortValue(from: rawTime) {
            let displayText = broadcastDisplayText(from: broadcast) ?? "\(rawTime) JST"
            return (rawTime, sortValue, displayText)
        }
        return ("播出時間未定", Int.max, broadcastDisplayText(from: broadcast) ?? "播出時間未定")
    }

    private static func sortValue(from time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return hour * 60 + minute
    }

    private static func broadcastDisplayText(from broadcast: AnimeBroadcastDTO?) -> String? {
        guard let broadcast else { return nil }
        if let raw = broadcast.string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            return AnimeDetailDateFormatting.translateBroadcastEnglishString(raw)
        }
        let time = broadcast.time?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return time.isEmpty ? nil : "\(time) JST"
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

    private static func posterURL(from dto: HomeTodayAnimeDTO) -> URL? {
        let raw =
            dto.images?.jpg?.largeImageUrl ??
            dto.images?.webp?.largeImageUrl ??
            dto.images?.jpg?.imageUrl ??
            dto.images?.webp?.imageUrl
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
        return String(format: "%.1f", score)
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

    private static func studioDisplayText(_ studios: [AnimeRelatedEntityDTO]?) -> String? {
        let names = (studios ?? []).compactMap { studio -> String? in
            guard let name = studio.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                return nil
            }
            return name
        }
        guard !names.isEmpty else { return nil }
        return names.prefix(2).joined(separator: "、")
    }

    private static func synopsisPreview(_ synopsis: String?) -> String? {
        guard let synopsis else { return nil }
        let trimmed = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let limit = 96
        if trimmed.count <= limit { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: limit)
        return String(trimmed[..<idx]) + "..."
    }

    // MARK: - Request State

    private func advanceRequestGeneration() -> Int {
        requestGeneration += 1
        return requestGeneration
    }

    private func isCurrentGeneration(_ generation: Int) -> Bool {
        generation == requestGeneration
    }

    private func deduplicatedItems(_ items: [HomeTodayAnimeTimelineItem]) -> [HomeTodayAnimeTimelineItem] {
        var seenIDs: Set<Int> = []
        return items.filter { item in
            seenIDs.insert(item.id).inserted
        }
    }

    private func mergedDeduplicatedItems(
        existing: [HomeTodayAnimeTimelineItem],
        incoming: [HomeTodayAnimeTimelineItem]
    ) -> [HomeTodayAnimeTimelineItem] {
        deduplicatedItems(existing + incoming)
    }
}
