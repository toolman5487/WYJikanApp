//
//  MangaCategoryDetailModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/2.
//

import Foundation

struct MangaCategoryFilter: Equatable, Sendable {
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
        case manga
        case novel
        case lightNovel
        case oneShot
        case doujinshi
        case manhwa
        case manhua

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "全部"
            case .manga: return "漫畫"
            case .novel: return "小說"
            case .lightNovel: return "輕小說"
            case .oneShot: return "單篇"
            case .doujinshi: return "同人誌"
            case .manhwa: return "韓漫"
            case .manhua: return "條漫／華漫"
            }
        }

        var apiValue: String? {
            switch self {
            case .all: return nil
            case .manga: return "manga"
            case .novel: return "novel"
            case .lightNovel: return "lightnovel"
            case .oneShot: return "oneshot"
            case .doujinshi: return "doujin"
            case .manhwa: return "manhwa"
            case .manhua: return "manhua"
            }
        }
    }
}

struct MangaCategoryPage: Sendable {
    let items: [MangaCategoryItemDTO]
    let currentPage: Int
    let hasNextPage: Bool
}

struct MangaCategoryResponse: Decodable, Sendable {
    let pagination: MangaCategoryPaginationDTO?
    let data: [MangaCategoryItemDTO]
}

struct MangaCategoryPaginationDTO: Decodable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

struct MangaCategoryItemDTO: Decodable, Identifiable, Hashable, Sendable {
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
    let chapters: Int?
    let volumes: Int?
    let images: MangaCategoryImagesDTO?
    let genres: [MangaCategoryGenreDTO]?

    var id: Int { malId }
}

struct MangaCategoryGenreDTO: Decodable, Hashable, Sendable {
    let malId: Int
    let name: String?

    var id: Int { malId }
}

struct MangaCategoryImagesDTO: Decodable, Hashable, Sendable {
    let jpg: MangaCategoryImageURLDTO?
    let webp: MangaCategoryImageURLDTO?
}

struct MangaCategoryImageURLDTO: Decodable, Hashable, Sendable {
    let imageUrl: String?
    let smallImageUrl: String?
    let largeImageUrl: String?
}

extension MangaCategoryItemDTO {
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
