//
//  AnimeDetailEpisodesListViewModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Combine
import Foundation
import OSLog

@MainActor
final class AnimeDetailEpisodesListViewModel: ObservableObject {
    enum ScreenState {
        case loading
        case empty
        case content
        case error(String)
    }

    enum LoadMoreState: Equatable {
        case hidden
        case available
        case loading
        case error(message: String)
    }

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var loadMoreState: LoadMoreState = .hidden
    @Published private(set) var episodes: [AnimeEpisodeDTO] = []
    @Published private(set) var episodeRows: [AnimeDetailEpisodeRowPresentation] = []
    @Published private(set) var expandedEpisodeIDs: Set<Int> = []
    @Published private(set) var episodeDetailStates: [Int: AnimeDetailEpisodeDetailPresentation] = [:]

    private let malId: Int
    private let service: any AnimeDetailServicing
    private var currentPage = 0
    private var hasNextPage = false
    private var hasLoaded = false
    private var isLoadingMore = false
    private var episodesByRowID: [Int: AnimeEpisodeDTO] = [:]

    private static let iso8601WithFractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fullDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

    private static let airedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(
        malId: Int,
        service: any AnimeDetailServicing = AnimeDetailService()
    ) {
        self.malId = malId
        self.service = service
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await loadFirstPage()
    }

    func loadMore() async {
        await loadMorePage()
    }

    func retryLoadMore() async {
        guard case .error = loadMoreState else { return }
        await loadMorePage()
    }

    func toggleEpisodeDetail(for rowID: Int) async {
        guard let episode = episodesByRowID[rowID],
              let episodeNumber = episode.malId else {
            return
        }

        if expandedEpisodeIDs.contains(episodeNumber) {
            expandedEpisodeIDs.remove(episodeNumber)
            rebuildEpisodeRows()
            return
        }

        expandedEpisodeIDs.insert(episodeNumber)
        rebuildEpisodeRows()
        guard episodeDetailStates[episodeNumber] == nil else { return }

        episodeDetailStates[episodeNumber] = .loading(expandedPresentation(for: episode))
        rebuildEpisodeRows()

        do {
            let response = try await service.fetchAnimeEpisodeDetail(
                malId: malId,
                episodeNumber: episodeNumber
            )
            let detailEpisode = response.data.mergedWithFallback(episode)
            episodeDetailStates[episodeNumber] = .content(expandedPresentation(for: detailEpisode))
            rebuildEpisodeRows()
        } catch is CancellationError {
            episodeDetailStates[episodeNumber] = .content(expandedPresentation(for: episode))
            rebuildEpisodeRows()
        } catch {
            episodeDetailStates[episodeNumber] = .error(
                error.localizedDescription,
                expandedPresentation(for: episode)
            )
            rebuildEpisodeRows()
        }
    }

    private func rowPresentation(for episode: AnimeEpisodeDTO) -> AnimeDetailEpisodeRowPresentation {
        let episodeID = episode.id
        let detail: AnimeDetailEpisodeDetailPresentation?
        if let malId = episode.malId, expandedEpisodeIDs.contains(malId) {
            detail = episodeDetailStates[malId] ?? .content(expandedPresentation(for: episode))
        } else {
            detail = nil
        }

        return AnimeDetailEpisodeRowPresentation(
            id: episodeID,
            summary: summaryPresentation(for: episode),
            detail: detail,
            isExpanded: episode.malId.map(expandedEpisodeIDs.contains) ?? false,
            canExpand: episode.malId != nil
        )
    }

    private func summaryPresentation(for episode: AnimeEpisodeDTO) -> AnimeDetailEpisodeSummaryPresentation {
        AnimeDetailEpisodeSummaryPresentation(
            episodeNumberText: episodeNumberText(for: episode),
            title: displayTitle(for: episode),
            airedText: airedDisplayText(for: episode),
            synopsisText: synopsisText(for: episode),
            tagTexts: tagTexts(for: episode)
        )
    }

    private func expandedPresentation(for episode: AnimeEpisodeDTO) -> AnimeDetailEpisodeExpandedPresentation {
        AnimeDetailEpisodeExpandedPresentation(
            alternateTitle: alternateTitle(for: episode),
            infoItems: infoItems(for: episode),
            synopsisText: synopsisText(for: episode),
            externalLinks: externalLinks(for: episode)
        )
    }

    private func infoItems(for episode: AnimeEpisodeDTO) -> [AnimeDetailEpisodeInfoItem] {
        [
            AnimeDetailEpisodeInfoItem(title: "播出", value: airedDisplayText(for: episode) ?? "-"),
            AnimeDetailEpisodeInfoItem(title: "片長", value: durationDisplayText(for: episode) ?? "-"),
            AnimeDetailEpisodeInfoItem(title: "類型", value: episodeTypeText(for: episode))
        ]
    }

    private func externalLinks(for episode: AnimeEpisodeDTO) -> [AnimeDetailEpisodeExternalLink] {
        var links: [AnimeDetailEpisodeExternalLink] = []

        if let url = myAnimeListURL(for: episode) {
            links.append(
                AnimeDetailEpisodeExternalLink(
                    kind: .myAnimeList,
                    title: "MAL",
                    systemImage: "arrow.up.forward.app",
                    url: url
                )
            )
        }

        if let url = discussionURL(for: episode) {
            links.append(
                AnimeDetailEpisodeExternalLink(
                    kind: .discussion,
                    title: "討論",
                    systemImage: "bubble.left.and.bubble.right",
                    url: url
                )
            )
        }

        return links
    }

    private func episodeNumberText(for episode: AnimeEpisodeDTO) -> String {
        if let malId = episode.malId {
            return "EP \(malId)"
        }
        return "EP"
    }

    private func displayTitle(for episode: AnimeEpisodeDTO) -> String {
        let candidates = [
            episode.titleJapanese,
            episode.titleRomanji,
            episode.title
        ]
        for candidate in candidates {
            if let candidate = trimmed(candidate) {
                return candidate
            }
        }
        return "未命名集數"
    }

    private func alternateTitle(for episode: AnimeEpisodeDTO) -> String? {
        let primaryTitle = displayTitle(for: episode)
        let candidates = [
            episode.titleRomanji,
            episode.title
        ]
        for candidate in candidates {
            if let title = trimmed(candidate), title != primaryTitle {
                return title
            }
        }
        return nil
    }

    private func airedDisplayText(for episode: AnimeEpisodeDTO) -> String? {
        guard let aired = trimmed(episode.aired) else { return nil }
        guard let date = dateFromISOString(aired) else { return aired }
        return Self.airedDateFormatter.string(from: date)
    }

    private func durationDisplayText(for episode: AnimeEpisodeDTO) -> String? {
        guard let duration = episode.duration, duration > 0 else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60

        if minutes > 0, seconds > 0 {
            return "\(minutes) 分 \(seconds) 秒"
        }
        if minutes > 0 {
            return "\(minutes) 分鐘"
        }
        return "\(seconds) 秒"
    }

    private func episodeTypeText(for episode: AnimeEpisodeDTO) -> String {
        let tags = tagTexts(for: episode)
        return tags.isEmpty ? "一般集數" : tags.joined(separator: "、")
    }

    private func tagTexts(for episode: AnimeEpisodeDTO) -> [String] {
        var result: [String] = []
        if episode.filler == true {
            result.append("Filler")
        }
        if episode.recap == true {
            result.append("Recap")
        }
        return result
    }

    private func synopsisText(for episode: AnimeEpisodeDTO) -> String? {
        trimmed(episode.synopsis)
    }

    private func myAnimeListURL(for episode: AnimeEpisodeDTO) -> URL? {
        makeURL(from: episode.url)
    }

    private func discussionURL(for episode: AnimeEpisodeDTO) -> URL? {
        makeURL(from: episode.forumUrl)
    }

    private func loadFirstPage() async {
        resetPagination()
        screenState = .loading

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: 1)
            hasLoaded = true
            currentPage = 1
            hasNextPage = resolvedHasNextPage(
                from: response.pagination,
                responseData: response.data
            )
            episodes = response.data
            refreshEpisodeCaches()
            rebuildEpisodeRows()
            screenState = episodes.isEmpty ? .empty : .content
            loadMoreState = resolvedLoadMoreState()
        } catch is CancellationError {
        } catch {
            screenState = .error(error.localizedDescription)
            loadMoreState = .hidden
        }
    }

    private func loadMorePage() async {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return }

        isLoadingMore = true
        loadMoreState = .loading

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: currentPage + 1)
            currentPage += 1
            hasNextPage = resolvedHasNextPage(
                from: response.pagination,
                responseData: response.data
            )
            episodes.append(contentsOf: response.data)
            refreshEpisodeCaches()
            rebuildEpisodeRows()
            isLoadingMore = false
            loadMoreState = resolvedLoadMoreState()
        } catch is CancellationError {
            isLoadingMore = false
            loadMoreState = resolvedLoadMoreState()
        } catch {
            AppLogger.network.error(
                "Anime episodes load-more failed: \(error.localizedDescription, privacy: .public)"
            )
            isLoadingMore = false
            loadMoreState = .error(message: "載入更多集數失敗")
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

    private func resolvedHasNextPage(
        from pagination: AnimeEpisodesPaginationDTO?,
        responseData: [AnimeEpisodeDTO]
    ) -> Bool {
        switch (pagination?.hasNextPage, pagination?.lastVisiblePage) {
        case (.some(let hasNextPage), _):
            return hasNextPage
        case (.none, .some(let lastVisiblePage)):
            return currentPage < lastVisiblePage
        case (.none, .none):
            return !responseData.isEmpty
        }
    }

    private func trimmed(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    private func makeURL(from rawValue: String?) -> URL? {
        guard let rawValue = trimmed(rawValue) else { return nil }
        return URL(string: rawValue)
    }

    private func dateFromISOString(_ raw: String) -> Date? {
        if let date = Self.iso8601WithFractionalSecondsFormatter.date(from: raw) {
            return date
        }

        if let date = Self.iso8601Formatter.date(from: raw) {
            return date
        }

        return Self.fullDateFormatter.date(from: raw)
    }

    private func refreshEpisodeCaches() {
        episodesByRowID = Dictionary(uniqueKeysWithValues: episodes.map { ($0.id, $0) })
    }

    private func rebuildEpisodeRows() {
        episodeRows = episodes.map(rowPresentation(for:))
    }
}
