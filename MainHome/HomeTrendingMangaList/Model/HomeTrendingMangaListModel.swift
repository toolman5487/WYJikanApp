//
//  HomeTrendingMangaListModel.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/6.
//

import Foundation

enum HomeTrendingMangaListSort: String, CaseIterable, Identifiable, Sendable {
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
}

enum HomeTrendingMangaListFormat: String, CaseIterable, Identifiable, Sendable {
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

    func matches(type rawType: String?) -> Bool {
        guard self != .all else { return true }
        guard let rawType else { return false }
        return normalizedMatchValues.contains(Self.normalized(rawType))
    }

    private var normalizedMatchValues: Set<String> {
        switch self {
        case .all:
            return []
        case .manga:
            return ["manga"]
        case .novel:
            return ["novel"]
        case .lightNovel:
            return ["lightnovel"]
        case .oneShot:
            return ["oneshot"]
        case .doujinshi:
            return ["doujinshi"]
        case .manhwa:
            return ["manhwa"]
        case .manhua:
            return ["manhua"]
        }
    }

    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z]",
                with: "",
                options: .regularExpression
            )
    }
}
