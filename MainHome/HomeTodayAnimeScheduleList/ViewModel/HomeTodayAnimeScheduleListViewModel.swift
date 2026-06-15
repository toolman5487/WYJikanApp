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
        case error(FeatureLoadFailure)
    }

    typealias LoadMoreState = PaginationFooterState

    // MARK: - Published State

    @Published var selectedDay: HomeScheduleDay
    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden

    // MARK: - Dependencies

    private let service: HomeTodayAnimeScheduleListServicing

    // MARK: - Pagination State

    private let pageSize = 25
    private let paginationController = PaginatedListLoadingController<HomeTodayAnimeTimelineItem>()
    private var loadMoreTriggerIDs: Set<Int> = []
    private var cancellables: Set<AnyCancellable> = []
    private var dayRequestTask: Task<Void, Never>?

    // MARK: - Init

    init(
        initialDay: HomeScheduleDay = .current(),
        service: HomeTodayAnimeScheduleListServicing
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

    func loadMoreIfNeeded(currentItem item: HomeTodayAnimeTimelineItem) async {
        guard shouldLoadMore(after: item) else { return }
        await loadMorePage()
    }

    func updateSelectedDay(_ day: HomeScheduleDay) {
        guard selectedDay != day else { return }
        selectedDay = day
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

    private func fetchFirstPage(showSkeleton: Bool) async {
        loadMoreTriggerIDs = []
        dayRequestTask = nil
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
            fetchPage: fetchPage,
            setFooterState: applyFooterState,
            applyPresentation: applyPresentation
        )
    }

    private func fetchPage(_ page: Int) async throws -> PaginatedPage<HomeTodayAnimeTimelineItem> {
        let response = try await service.fetchSchedulePage(
            day: selectedDay,
            page: page,
            limit: pageSize
        )
        return PaginatedPage(
            items: response.data.compactMap(Self.timelineItem(from:)),
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

    private func applyPresentation(items: [HomeTodayAnimeTimelineItem], footerState: PaginationFooterState) {
        guard !items.isEmpty else {
            screenState = .empty
            loadMoreState = footerState
            return
        }

        screenState = .content(sections: groupedSections(from: items))
        loadMoreTriggerIDs = Set(items.suffix(5).map(\.id))
        loadMoreState = footerState
    }

    private func shouldLoadMore(after item: HomeTodayAnimeTimelineItem) -> Bool {
        guard paginationController.canLoadMore else { return false }
        return loadMoreTriggerIDs.contains(item.id)
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
        if let presentation = AnimeDetailDateFormatting.localBroadcastPresentation(from: broadcast) {
            return (
                presentation.sectionTitle,
                presentation.sortValue,
                presentation.displayText
            )
        }

        return ("播出時間未定", Int.max, broadcastDisplayText(from: broadcast) ?? "播出時間未定")
    }

    private static func broadcastDisplayText(from broadcast: AnimeBroadcastDTO?) -> String? {
        guard let broadcast else { return nil }
        if let raw = broadcast.string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
            return AnimeDetailDateFormatting.localBroadcastFromEnglishString(raw)
                ?? AnimeDetailDateFormatting.translateBroadcastEnglishString(raw)
        }

        let day = broadcast.day?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let time = broadcast.time?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !day.isEmpty, !time.isEmpty else { return nil }

        return AnimeDetailDateFormatting.localBroadcastString(
            dayEnglish: day,
            timeHHMM: time,
            sourceTimeZoneIdentifier: AnimeDetailDateFormatting.sourceTimeZoneIdentifier(for: broadcast)
        ) ?? "\(AnimeDetailDateFormatting.weekdayChinese(from: day)) \(time)"
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

}
