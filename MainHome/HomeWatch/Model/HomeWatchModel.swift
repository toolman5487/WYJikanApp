//
//  HomeWatchModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import Foundation

// MARK: - Response

nonisolated struct HomeWatchPromosResponse: Codable, Sendable {
    let pagination: HomeWatchPaginationDTO?
    let data: [HomeWatchPromoDTO]
}

nonisolated struct HomeWatchEpisodesResponse: Codable, Sendable {
    let pagination: HomeWatchPaginationDTO?
    let data: [HomeWatchEpisodeGroupDTO]
}

nonisolated struct HomeWatchPaginationDTO: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

nonisolated struct HomeWatchPromoDTO: Codable, Hashable, Sendable {
    let title: String?
    let entry: HomeWatchEntryDTO?
    let trailer: HomeWatchTrailerDTO?
}

nonisolated struct HomeWatchEpisodeGroupDTO: Codable, Hashable, Sendable {
    let entry: HomeWatchEntryDTO?
    let episodes: [HomeWatchEpisodeDTO]
    let regionLocked: Bool?
}

nonisolated struct HomeWatchEntryDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?

    var id: Int { malId }
}

nonisolated struct HomeWatchEpisodeDTO: Codable, Hashable, Sendable {
    let malId: Int?
    let url: String?
    let title: String?
    let premium: Bool?
}

nonisolated struct HomeWatchTrailerDTO: Codable, Hashable, Sendable {
    let youtubeId: String?
    let url: String?
    let embedUrl: String?
    let images: HomeWatchTrailerImagesDTO?
}

nonisolated struct HomeWatchTrailerImagesDTO: Codable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let mediumImageUrl: String?
    let largeImageUrl: String?
    let maximumImageUrl: String?
}

// MARK: - Presentation

nonisolated enum HomeWatchEpisodeFeed: Sendable {
    case latest
    case popular
}

nonisolated enum HomeWatchPromoFeed: Sendable {
    case latest
    case popular
}

nonisolated enum HomeWatchContentKind: Sendable {
    case episode
    case promo

    var title: String {
        switch self {
        case .episode:
            return "集數"
        case .promo:
            return "預告"
        }
    }
}

nonisolated enum HomeWatchFeedKind: String, CaseIterable, Identifiable, Sendable {
    case latestEpisodes
    case popularEpisodes
    case latestPromos
    case popularPromos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latestEpisodes:
            return "最新集數"
        case .popularEpisodes:
            return "熱門集數"
        case .latestPromos:
            return "最新預告"
        case .popularPromos:
            return "熱門預告"
        }
    }

    var subtitle: String {
        switch self {
        case .latestEpisodes:
            return "追蹤最近上架的可觀看動畫集數。"
        case .popularEpisodes:
            return "整理目前最多人關注的可觀看集數。"
        case .latestPromos:
            return "瀏覽最新公開的宣傳影片、廣告與預告片。"
        case .popularPromos:
            return "查看近期最常被觀看的動畫預告。"
        }
    }

    var systemImageName: String {
        switch self {
        case .latestEpisodes:
            return "play.rectangle.on.rectangle"
        case .popularEpisodes:
            return "flame"
        case .latestPromos:
            return "film"
        case .popularPromos:
            return "play.circle"
        }
    }

    var contentKind: HomeWatchContentKind {
        switch self {
        case .latestEpisodes, .popularEpisodes:
            return .episode
        case .latestPromos, .popularPromos:
            return .promo
        }
    }

    var episodeFeed: HomeWatchEpisodeFeed? {
        switch self {
        case .latestEpisodes:
            return .latest
        case .popularEpisodes:
            return .popular
        case .latestPromos, .popularPromos:
            return nil
        }
    }

    var promoFeed: HomeWatchPromoFeed? {
        switch self {
        case .latestPromos:
            return .latest
        case .popularPromos:
            return .popular
        case .latestEpisodes, .popularEpisodes:
            return nil
        }
    }
}

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
    case error(String)
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
