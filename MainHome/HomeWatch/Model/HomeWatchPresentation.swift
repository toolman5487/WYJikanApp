//
//  HomeWatchPresentation.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

nonisolated struct HomeWatchFeedChipItem: Hashable, Sendable {
    let feed: HomeWatchFeedKind
    let isSelected: Bool

    var title: String { feed.title }
    var systemImageName: String { feed.systemImageName }
}

nonisolated struct HomeWatchListHeaderContent: Equatable, Sendable {
    let title: String
    let subtitle: String
    let loadedCountText: String
}

nonisolated enum HomeWatchSectionState<Item: Equatable & Sendable>: Equatable, Sendable {
    case loading
    case error(FeatureLoadFailure)
    case empty
    case content([Item])

    var items: [Item] {
        switch self {
        case .content(let items):
            return items
        case .loading, .error, .empty:
            return []
        }
    }

    var hasContent: Bool {
        switch self {
        case .content:
            return true
        case .loading, .error, .empty:
            return false
        }
    }
}

nonisolated struct HomeWatchPromoItem: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let animeID: Int
    let animeTitle: String
    let promoTitle: String
    let thumbnailURL: URL?
    let watchURL: URL?
}

nonisolated struct HomeWatchEpisodeItem: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let title: String
    let imageURL: URL
    let episodeText: String
    let episodeURL: URL?
    let badgeTexts: [String]
}

nonisolated struct HomeWatchListItem: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let animeID: Int
    let title: String
    let subtitle: String
    let imageURL: URL?
    let badgeTexts: [String]
    let actionURL: URL?
    let contentKind: HomeWatchContentKind
}

nonisolated enum HomeWatchPresentationText {
    static func title(from entry: HomeWatchEntryDTO) -> String {
        normalizedText(entry.titleJapanese) ??
        normalizedText(entry.titleEnglish) ??
        normalizedText(entry.title) ??
        "未命名作品"
    }

    static func episodeText(title: String?, episodeID: Int?, fallback: String) -> String {
        if let title = normalizedText(title) {
            return localizedEpisodeTitle(from: title)
        }

        if let episodeID {
            return "第 \(episodeID) 集"
        }

        return fallback
    }

    static func normalizedText(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    private static func localizedEpisodeTitle(from title: String) -> String {
        let pattern = #"^Episode\s+([0-9]+)(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return title
        }

        let range = NSRange(title.startIndex..<title.endIndex, in: title)
        guard let match = regex.firstMatch(in: title, range: range),
              let numberRange = Range(match.range(at: 1), in: title) else {
            return title
        }

        let numberText = String(title[numberRange])
        let suffixText: String
        if let suffixRange = Range(match.range(at: 2), in: title) {
            suffixText = String(title[suffixRange])
                .trimmingCharacters(in: CharacterSet(charactersIn: " -–—:："))
        } else {
            suffixText = ""
        }

        guard !suffixText.isEmpty else {
            return "第 \(numberText) 集"
        }

        return "第 \(numberText) 集 \(suffixText)"
    }
}

nonisolated enum HomeWatchPresentationBuilder {
    static func promoItems(
        from response: HomeWatchPromosResponse,
        limit: Int
    ) -> [HomeWatchPromoItem] {
        let items = response.data.compactMap(promoItem(from:))
        return Array(deduplicated(items, by: \.id).prefix(limit))
    }

    static func episodeItems(
        from response: HomeWatchEpisodesResponse,
        limit: Int
    ) -> [HomeWatchEpisodeItem] {
        let items = response.data.compactMap(episodeItem(from:))
        return Array(deduplicated(items, by: \.id).prefix(limit))
    }

    static func listItems(
        from response: HomeWatchEpisodesResponse,
        feed: HomeWatchFeedKind
    ) -> [HomeWatchListItem] {
        response.data.compactMap { listItem(from: $0, feed: feed) }
    }

    static func listItems(
        from response: HomeWatchPromosResponse,
        feed: HomeWatchFeedKind
    ) -> [HomeWatchListItem] {
        response.data.compactMap { listItem(from: $0, feed: feed) }
    }

    private static func promoItem(from dto: HomeWatchPromoDTO) -> HomeWatchPromoItem? {
        guard let entry = dto.entry else { return nil }
        let promoTitle = HomeWatchPresentationText.normalizedText(dto.title) ?? "最新預告"
        let watchURL = watchURL(from: dto.trailer)
        let thumbnailURL = thumbnailURL(from: dto.trailer) ?? posterURL(from: entry.images)
        let id = promoID(
            feedID: nil,
            entryID: entry.malId,
            title: promoTitle,
            watchURL: watchURL,
            thumbnailURL: thumbnailURL
        )

        return HomeWatchPromoItem(
            id: id,
            animeID: entry.malId,
            animeTitle: HomeWatchPresentationText.title(from: entry),
            promoTitle: promoTitle,
            thumbnailURL: thumbnailURL,
            watchURL: watchURL
        )
    }

    private static func episodeItem(from dto: HomeWatchEpisodeGroupDTO) -> HomeWatchEpisodeItem? {
        guard let entry = dto.entry,
              let imageURL = posterURL(from: entry.images) else {
            return nil
        }

        let firstEpisode = dto.episodes.first

        return HomeWatchEpisodeItem(
            id: entry.malId,
            title: HomeWatchPresentationText.title(from: entry),
            imageURL: imageURL,
            episodeText: episodeText(from: firstEpisode),
            episodeURL: url(from: firstEpisode?.url),
            badgeTexts: episodeBadgeTexts(from: dto, includesContentKind: false)
        )
    }

    private static func listItem(
        from dto: HomeWatchEpisodeGroupDTO,
        feed: HomeWatchFeedKind
    ) -> HomeWatchListItem? {
        guard let entry = dto.entry else { return nil }
        let firstEpisode = dto.episodes.first

        return HomeWatchListItem(
            id: "\(feed.id)-episode-\(entry.malId)",
            animeID: entry.malId,
            title: HomeWatchPresentationText.title(from: entry),
            subtitle: episodeText(from: firstEpisode),
            imageURL: posterURL(from: entry.images),
            badgeTexts: episodeBadgeTexts(from: dto, includesContentKind: true),
            actionURL: url(from: firstEpisode?.url),
            contentKind: .episode
        )
    }

    private static func listItem(
        from dto: HomeWatchPromoDTO,
        feed: HomeWatchFeedKind
    ) -> HomeWatchListItem? {
        guard let entry = dto.entry else { return nil }
        let promoTitle = HomeWatchPresentationText.normalizedText(dto.title) ?? "最新預告"
        let watchURL = watchURL(from: dto.trailer)
        let thumbnailURL = thumbnailURL(from: dto.trailer) ?? posterURL(from: entry.images)

        return HomeWatchListItem(
            id: promoID(
                feedID: feed.id,
                entryID: entry.malId,
                title: promoTitle,
                watchURL: watchURL,
                thumbnailURL: thumbnailURL
            ),
            animeID: entry.malId,
            title: HomeWatchPresentationText.title(from: entry),
            subtitle: promoTitle,
            imageURL: thumbnailURL,
            badgeTexts: ["預告"],
            actionURL: watchURL,
            contentKind: .promo
        )
    }

    private static func episodeText(from episode: HomeWatchEpisodeDTO?) -> String {
        guard let episode else { return "最新集數" }

        return HomeWatchPresentationText.episodeText(
            title: episode.title,
            episodeID: episode.malId,
            fallback: "最新集數"
        )
    }

    private static func episodeBadgeTexts(
        from dto: HomeWatchEpisodeGroupDTO,
        includesContentKind: Bool
    ) -> [String] {
        var badges: [String] = includesContentKind ? ["集數"] : []

        if dto.regionLocked == true {
            badges.append("地區限制")
        }

        if dto.episodes.contains(where: { $0.premium == true }) {
            badges.append("付費")
        }

        return badges
    }

    private static func promoID(
        feedID: String?,
        entryID: Int,
        title: String,
        watchURL: URL?,
        thumbnailURL: URL?
    ) -> String {
        [
            feedID,
            "promo",
            String(entryID),
            title,
            watchURL?.absoluteString ?? thumbnailURL?.absoluteString ?? "item"
        ]
        .compactMap { $0 }
        .joined(separator: "-")
    }

    private static func watchURL(from trailer: HomeWatchTrailerDTO?) -> URL? {
        if let youtubeID = HomeWatchPresentationText.normalizedText(trailer?.youtubeId),
           let watchURL = YouTubeVideoURLResolver.watchURL(videoID: youtubeID) {
            return watchURL
        }

        if let url = url(from: trailer?.url) {
            return normalizedYouTubeWatchURL(from: url) ?? url
        }

        if let embedURL = url(from: trailer?.embedUrl) {
            return normalizedYouTubeWatchURL(from: embedURL) ?? embedURL
        }

        return nil
    }

    private static func normalizedYouTubeWatchURL(from url: URL) -> URL? {
        guard let videoID = YouTubeVideoURLResolver.videoID(from: url) else {
            return nil
        }

        return YouTubeVideoURLResolver.watchURL(videoID: videoID)
    }

    private static func thumbnailURL(from trailer: HomeWatchTrailerDTO?) -> URL? {
        [
            trailer?.images?.maximumImageUrl,
            trailer?.images?.largeImageUrl,
            trailer?.images?.mediumImageUrl,
            trailer?.images?.imageUrl,
            trailer?.images?.smallImageUrl
        ]
        .compactMap(url(from:))
        .first
    }

    private static func posterURL(from images: AnimeImagesDTO?) -> URL? {
        JikanImageURLResolver.url(from: images, tier: .poster)
    }

    private static func url(from value: String?) -> URL? {
        guard let text = HomeWatchPresentationText.normalizedText(value) else { return nil }
        return URL(string: text)
    }

    private static func deduplicated<Item, ID: Hashable>(
        _ items: [Item],
        by keyPath: KeyPath<Item, ID>
    ) -> [Item] {
        var seenIDs: Set<ID> = []
        return items.filter { item in
            seenIDs.insert(item[keyPath: keyPath]).inserted
        }
    }
}
