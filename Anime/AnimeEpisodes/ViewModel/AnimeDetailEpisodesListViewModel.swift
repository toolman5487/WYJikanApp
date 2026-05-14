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

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var episodes: [AnimeEpisodeDTO] = []
    @Published private(set) var hasNextPage = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var expandedEpisodeID: Int?
    @Published private(set) var episodeDetailStates: [Int: AnimeDetailEpisodeDetailPresentation] = [:]

    private let malId: Int
    private let service: any AnimeDetailServicing
    private var currentPage = 0
    private var hasLoaded = false

    init(
        malId: Int,
        service: any AnimeDetailServicing = AnimeDetailService()
    ) {
        self.malId = malId
        self.service = service
    }

    var episodeRows: [AnimeDetailEpisodeRowPresentation] {
        episodes.map(rowPresentation(for:))
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await loadFirstPage()
    }

    func loadMore() async {
        guard hasLoaded, hasNextPage, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: currentPage + 1)
            currentPage += 1
            hasNextPage = response.pagination?.hasNextPage == true
            episodes.append(contentsOf: response.data)
        } catch is CancellationError {
        } catch {
            AppLogger.network.error(
                "Anime episodes load-more failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    func toggleEpisodeDetail(for rowID: Int) async {
        guard let episode = episodes.first(where: { $0.id == rowID }),
              let episodeNumber = episode.malId else {
            return
        }

        if expandedEpisodeID == episodeNumber {
            expandedEpisodeID = nil
            return
        }

        expandedEpisodeID = episodeNumber
        guard episodeDetailStates[episodeNumber] == nil else { return }

        episodeDetailStates[episodeNumber] = .loading(expandedPresentation(for: episode))

        do {
            let response = try await service.fetchAnimeEpisodeDetail(
                malId: malId,
                episodeNumber: episodeNumber
            )
            let detailEpisode = response.data.mergedWithFallback(episode)
            episodeDetailStates[episodeNumber] = .content(expandedPresentation(for: detailEpisode))
        } catch is CancellationError {
            episodeDetailStates[episodeNumber] = .content(expandedPresentation(for: episode))
        } catch {
            episodeDetailStates[episodeNumber] = .error(
                error.localizedDescription,
                expandedPresentation(for: episode)
            )
        }
    }

    private func rowPresentation(for episode: AnimeEpisodeDTO) -> AnimeDetailEpisodeRowPresentation {
        let episodeID = episode.id
        let detail: AnimeDetailEpisodeDetailPresentation?
        if let malId = episode.malId, expandedEpisodeID == malId {
            detail = episodeDetailStates[malId] ?? .content(expandedPresentation(for: episode))
        } else {
            detail = nil
        }

        return AnimeDetailEpisodeRowPresentation(
            id: episodeID,
            summary: summaryPresentation(for: episode),
            detail: detail,
            isExpanded: episode.malId == expandedEpisodeID,
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

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
        screenState = .loading

        do {
            let response = try await service.fetchAnimeEpisodes(malId: malId, page: 1)
            hasLoaded = true
            currentPage = 1
            hasNextPage = response.pagination?.hasNextPage == true
            episodes = response.data
            screenState = episodes.isEmpty ? .empty : .content
        } catch is CancellationError {
        } catch {
            screenState = .error(error.localizedDescription)
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
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: raw) {
            return date
        }

        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: raw) {
            return date
        }

        iso.formatOptions = [.withFullDate]
        return iso.date(from: raw)
    }
}
