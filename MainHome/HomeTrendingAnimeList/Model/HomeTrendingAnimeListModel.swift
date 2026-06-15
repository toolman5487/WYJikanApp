//
//  HomeTrendingAnimeListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import Foundation

// MARK: - HomeTrendingAnimeListSort

nonisolated enum HomeTrendingAnimeListSort: String, CaseIterable, Identifiable, Sendable {
    case apiDefault
    case rank
    case popularity
    case score

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apiDefault: return "預設"
        case .rank: return "排名"
        case .popularity: return "人氣"
        case .score: return "評分"
        }
    }

    var systemImageName: String {
        switch self {
        case .apiDefault: return "sparkles"
        case .rank: return "number"
        case .popularity: return "flame"
        case .score: return "star"
        }
    }
}

// MARK: - API Models

nonisolated struct HomeTrendingAnimeListResponse: Codable, Sendable {
    let pagination: HomeTrendingAnimeListPaginationDTO?
    let data: [HomeTrendingAnimeListDTO]
}

nonisolated struct HomeTrendingAnimeListPaginationDTO: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

nonisolated struct HomeTrendingAnimeListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let synopsis: String?
    let type: String?
    let score: Double?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let episodes: Int?
    let status: String?
    let season: String?
    let year: Int?
    let images: AnimeImagesDTO?

    var id: Int { malId }
}

// MARK: - Presentation Models

nonisolated struct HomeTrendingAnimeListItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let typeText: String?
    let scoreText: String?
    let rank: Int?
    let popularityText: String?
    let membersText: String?
    let episodeText: String?
    let statusText: String?
    let seasonText: String?
    let synopsisPreview: String?
    let imageURL: URL?
}

nonisolated struct HomeTrendingAnimeListHeaderContent: Hashable, Sendable {
    let title: String
    let subtitle: String
    let loadedCountText: String
}

nonisolated struct HomeTrendingAnimeListSortChipItem: Identifiable, Hashable, Sendable {
    let sort: HomeTrendingAnimeListSort
    let isSelected: Bool

    var id: String { sort.id }
    var title: String { sort.title }
    var systemImageName: String { sort.systemImageName }
}

nonisolated struct HomeTrendingAnimeListSectionContent: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let countText: String
    let items: [HomeTrendingAnimeListItem]
}

nonisolated struct HomeTrendingAnimeListContent: Hashable, Sendable {
    let sections: [HomeTrendingAnimeListSectionContent]
}
