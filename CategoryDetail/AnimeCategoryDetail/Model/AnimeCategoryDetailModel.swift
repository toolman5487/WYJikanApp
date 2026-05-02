//
//  AnimeCategoryDetailModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation

struct AnimeCategoryFilter: Equatable, Sendable {
    let sort: Sort
    let format: Format

    enum Sort: String, CaseIterable, Equatable, Identifiable, Sendable {
        case `default`
        case popularity
        case score
        case rank
        case newest
        case oldest

        var id: String { rawValue }

        var title: String {
            switch self {
            case .default: return "預設"
            case .popularity: return "人氣"
            case .score: return "評分"
            case .rank: return "排名"
            case .newest: return "最新"
            case .oldest: return "最舊"
            }
        }
    }

    enum Format: String, CaseIterable, Equatable, Identifiable, Sendable {
        case all
        case tv
        case movie
        case ova

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "全部"
            case .tv: return "TV"
            case .movie: return "Movie"
            case .ova: return "OVA"
            }
        }
    }
}

struct AnimeCategoryPage: Sendable {
    let items: [AnimeCategoryItemDTO]
    let currentPage: Int
    let hasNextPage: Bool
}

struct AnimeCategoryResponse: Decodable, Sendable {
    let pagination: AnimeCategoryPaginationDTO?
    let data: [AnimeCategoryItemDTO]
}

struct AnimeCategoryPaginationDTO: Decodable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

struct AnimeCategoryItemDTO: Decodable, Identifiable, Hashable, Sendable {
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

struct AnimeCategoryGenreDTO: Decodable, Hashable, Sendable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

struct AnimeCategoryImagesDTO: Decodable, Hashable, Sendable {
    let jpg: AnimeCategoryImageURLDTO?
    let webp: AnimeCategoryImageURLDTO?
}

struct AnimeCategoryImageURLDTO: Decodable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

extension AnimeCategoryItemDTO {
    var displayTitle: String {
        if let t = titleJapanese?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = titleEnglish?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        return "未命名作品"
    }

    var posterURL: URL? {
        let candidates = [
            images?.webp?.largeImageUrl,
            images?.jpg?.largeImageUrl,
            images?.webp?.imageUrl,
            images?.jpg?.imageUrl,
            images?.webp?.smallImageUrl,
            images?.jpg?.smallImageUrl
        ]
        for raw in candidates {
            if let raw, let url = URL(string: raw) {
                return url
            }
        }
        return nil
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
