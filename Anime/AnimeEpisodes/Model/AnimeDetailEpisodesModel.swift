//
//  AnimeDetailEpisodesModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/14.
//

import Foundation

nonisolated struct AnimeEpisodesResponse: Codable, Sendable {
    let pagination: AnimeEpisodesPaginationDTO?
    let data: [AnimeEpisodeDTO]
}

nonisolated struct AnimeEpisodeDetailResponse: Codable, Sendable {
    let data: AnimeEpisodeDTO
}

nonisolated struct AnimeEpisodesPaginationDTO: Codable, Hashable, Sendable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?
}

nonisolated struct AnimeEpisodeDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int?
    let url: String?
    let title: String?
    let titleJapanese: String?
    let titleRomanji: String?
    let duration: Int?
    let aired: String?
    let filler: Bool?
    let recap: Bool?
    let synopsis: String?
    let forumUrl: String?

    var id: Int {
        malId ?? ((title?.hashValue ?? 0) ^ (aired?.hashValue ?? 0))
    }

    func mergedWithFallback(_ fallback: AnimeEpisodeDTO) -> AnimeEpisodeDTO {
        AnimeEpisodeDTO(
            malId: malId ?? fallback.malId,
            url: url ?? fallback.url,
            title: title ?? fallback.title,
            titleJapanese: titleJapanese ?? fallback.titleJapanese,
            titleRomanji: titleRomanji ?? fallback.titleRomanji,
            duration: duration ?? fallback.duration,
            aired: aired ?? fallback.aired,
            filler: filler ?? fallback.filler,
            recap: recap ?? fallback.recap,
            synopsis: synopsis ?? fallback.synopsis,
            forumUrl: forumUrl ?? fallback.forumUrl
        )
    }
}

nonisolated struct AnimeDetailEpisodeRowPresentation: Identifiable, Sendable, Equatable {
    let id: Int
    let summary: AnimeDetailEpisodeSummaryPresentation
    let detail: AnimeDetailEpisodeDetailPresentation?
    let isExpanded: Bool
    let canExpand: Bool
}

nonisolated struct AnimeDetailEpisodeSummaryPresentation: Sendable, Equatable {
    let episodeNumberText: String
    let title: String
    let airedText: String?
    let synopsisText: String?
    let tagTexts: [String]
}

nonisolated enum AnimeDetailEpisodeDetailPresentation: Sendable, Equatable {
    case loading(AnimeDetailEpisodeExpandedPresentation)
    case content(AnimeDetailEpisodeExpandedPresentation)
    case error(String, AnimeDetailEpisodeExpandedPresentation)
}

nonisolated struct AnimeDetailEpisodeExpandedPresentation: Sendable, Equatable {
    let alternateTitle: String?
    let infoItems: [AnimeDetailEpisodeInfoItem]
    let synopsisText: String?
    let externalLinks: [AnimeDetailEpisodeExternalLink]
}

nonisolated struct AnimeDetailEpisodeInfoItem: Identifiable, Sendable, Equatable {
    let title: String
    let value: String

    var id: String {
        title
    }
}

nonisolated struct AnimeDetailEpisodeExternalLink: Identifiable, Sendable, Equatable {
    nonisolated enum Kind: Sendable, Equatable {
        case myAnimeList
        case discussion
    }

    let kind: Kind
    let title: String
    let systemImage: String
    let url: URL

    var id: String {
        "\(title)-\(url.absoluteString)"
    }
}
