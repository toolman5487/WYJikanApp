//
//  AnimeDetailEpisodeRowPresenter.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

struct AnimeDetailEpisodeRowPresenter: Sendable {
    func rowPresentation(
        for episode: AnimeEpisodeDTO,
        expandedEpisodeIDs: Set<Int>,
        episodeDetailStates: [Int: AnimeDetailEpisodeDetailPresentation]
    ) -> AnimeDetailEpisodeRowPresentation {
        let detail = detailPresentation(
            for: episode,
            expandedEpisodeIDs: expandedEpisodeIDs,
            episodeDetailStates: episodeDetailStates
        )

        return AnimeDetailEpisodeRowPresentation(
            id: episode.id,
            summary: summaryPresentation(for: episode),
            detail: detail,
            isExpanded: episode.malId.map(expandedEpisodeIDs.contains) ?? false,
            canExpand: episode.malId != nil
        )
    }

    func expandedPresentation(
        for episode: AnimeEpisodeDTO
    ) -> AnimeDetailEpisodeExpandedPresentation {
        AnimeDetailEpisodeExpandedPresentation(
            alternateTitle: alternateTitle(for: episode),
            infoItems: infoItems(for: episode),
            synopsisText: synopsisText(for: episode),
            externalLinks: externalLinks(for: episode)
        )
    }
}

// MARK: - Row Sections

private extension AnimeDetailEpisodeRowPresenter {
    func detailPresentation(
        for episode: AnimeEpisodeDTO,
        expandedEpisodeIDs: Set<Int>,
        episodeDetailStates: [Int: AnimeDetailEpisodeDetailPresentation]
    ) -> AnimeDetailEpisodeDetailPresentation? {
        guard let episodeNumber = episode.malId,
              expandedEpisodeIDs.contains(episodeNumber) else {
            return nil
        }

        return episodeDetailStates[episodeNumber] ?? .content(expandedPresentation(for: episode))
    }

    func summaryPresentation(
        for episode: AnimeEpisodeDTO
    ) -> AnimeDetailEpisodeSummaryPresentation {
        AnimeDetailEpisodeSummaryPresentation(
            episodeNumberText: episodeNumberText(for: episode),
            title: displayTitle(for: episode),
            airedText: airedDisplayText(for: episode),
            synopsisText: synopsisText(for: episode),
            tagTexts: tagTexts(for: episode)
        )
    }

    func infoItems(for episode: AnimeEpisodeDTO) -> [AnimeDetailEpisodeInfoItem] {
        [
            AnimeDetailEpisodeInfoItem(title: "播出", value: airedDisplayText(for: episode) ?? "-"),
            AnimeDetailEpisodeInfoItem(title: "片長", value: durationDisplayText(for: episode) ?? "-"),
            AnimeDetailEpisodeInfoItem(title: "類型", value: episodeTypeText(for: episode))
        ]
    }

    func externalLinks(for episode: AnimeEpisodeDTO) -> [AnimeDetailEpisodeExternalLink] {
        var links: [AnimeDetailEpisodeExternalLink] = []

        if let url = makeURL(from: episode.url) {
            links.append(
                AnimeDetailEpisodeExternalLink(
                    kind: .myAnimeList,
                    title: "MAL",
                    systemImage: "arrow.up.forward.app",
                    url: url
                )
            )
        }

        if let url = makeURL(from: episode.forumUrl) {
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
}

// MARK: - Text Formatting

private extension AnimeDetailEpisodeRowPresenter {
    func episodeNumberText(for episode: AnimeEpisodeDTO) -> String {
        guard let malId = episode.malId else {
            return "EP"
        }
        return "EP \(malId)"
    }

    func displayTitle(for episode: AnimeEpisodeDTO) -> String {
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

    func alternateTitle(for episode: AnimeEpisodeDTO) -> String? {
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

    func airedDisplayText(for episode: AnimeEpisodeDTO) -> String? {
        guard let aired = trimmed(episode.aired) else { return nil }
        guard let date = DisplayFormatters.DateParsing.date(fromISO8601: aired) else { return aired }
        return DisplayFormatters.DateDisplay.mediumDateString(from: date)
    }

    func durationDisplayText(for episode: AnimeEpisodeDTO) -> String? {
        guard let duration = episode.duration, duration > 0 else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60

        switch (minutes, seconds) {
        case let (minutes, seconds) where minutes > 0 && seconds > 0:
            return "\(minutes) 分 \(seconds) 秒"
        case let (minutes, _) where minutes > 0:
            return "\(minutes) 分鐘"
        case let (_, seconds):
            return "\(seconds) 秒"
        }
    }

    func episodeTypeText(for episode: AnimeEpisodeDTO) -> String {
        let tags = tagTexts(for: episode)
        return tags.isEmpty ? "一般集數" : tags.joined(separator: "、")
    }

    func tagTexts(for episode: AnimeEpisodeDTO) -> [String] {
        var result: [String] = []
        if episode.filler == true {
            result.append("Filler")
        }
        if episode.recap == true {
            result.append("Recap")
        }
        return result
    }

    func synopsisText(for episode: AnimeEpisodeDTO) -> String? {
        trimmed(episode.synopsis)
    }
}

// MARK: - Primitive Formatting

private extension AnimeDetailEpisodeRowPresenter {
    func trimmed(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    func makeURL(from rawValue: String?) -> URL? {
        guard let rawValue = trimmed(rawValue) else { return nil }
        return URL(string: rawValue)
    }

}
