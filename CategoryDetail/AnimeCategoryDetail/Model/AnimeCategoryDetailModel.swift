//
//  AnimeCategoryDetailModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation

nonisolated struct AnimeCategoryFilter: Equatable, Sendable {
    let sort: Sort
    let format: Format

    nonisolated enum Sort: String, CaseIterable, Equatable, Identifiable, Sendable {
        case defaultSort
        case popularity
        case score
        case rank
        case newest
        case oldest

        var id: String { rawValue }

        var title: String {
            switch self {
            case .defaultSort: return "預設"
            case .popularity: return "人氣"
            case .score: return "評分"
            case .rank: return "排名"
            case .newest: return "最新"
            case .oldest: return "最舊"
            }
        }
    }

    nonisolated enum Format: String, CaseIterable, Equatable, Identifiable, Sendable {
        case all
        case tv
        case movie
        case ova
        case ona
        case special
        case music

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "全部"
            case .tv: return "電視動畫"
            case .movie: return "劇場版"
            case .ova: return "OVA"
            case .ona: return "ONA"
            case .special: return "特別篇"
            case .music: return "音樂"
            }
        }

        var apiValue: String? {
            switch self {
            case .all: return nil
            case .tv: return "tv"
            case .movie: return "movie"
            case .ova: return "ova"
            case .ona: return "ona"
            case .special: return "special"
            case .music: return "music"
            }
        }
    }
}

nonisolated struct AnimeCategoryPage: Sendable {
    let items: [AnimeCategoryItemDTO]
    let currentPage: Int
    let hasNextPage: Bool
}

nonisolated struct AnimeCategoryResponse: Decodable, Sendable {
    let pagination: AnimeCategoryPaginationDTO?
    let data: [AnimeCategoryItemDTO]
}

nonisolated struct AnimeCategoryPaginationDTO: Decodable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

nonisolated struct AnimeCategoryItemDTO: Decodable, Identifiable, Hashable, Sendable {
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
    let year: Int?
    let images: AnimeCategoryImagesDTO?
    let genres: [AnimeCategoryGenreDTO]?

    var id: Int { malId }
}

nonisolated struct AnimeCategoryGenreDTO: Decodable, Hashable, Sendable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

nonisolated struct AnimeCategoryImagesDTO: Decodable, Hashable, Sendable {
    let jpg: AnimeCategoryImageURLDTO?
    let webp: AnimeCategoryImageURLDTO?
}

nonisolated struct AnimeCategoryImageURLDTO: Decodable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

nonisolated extension AnimeCategoryItemDTO {
    var displayTitle: String {
        if let t = titleJapanese?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = titleEnglish?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        return "未命名作品"
    }

    var posterURL: URL? {
        JikanImageURLResolver.url(from: images, tier: .poster)
    }

    var synopsisPreview: String? {
        guard let synopsis else { return nil }
        let trimmed = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let limit = 160
        if trimmed.count <= limit { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: limit)
        return String(trimmed[..<idx]) + "…"
    }
}
