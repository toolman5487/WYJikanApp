//
//  CharacterListModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/20.
//

import Foundation

enum CharacterListSort: String, CaseIterable, Hashable, Sendable {
    case popularity
    case nameAscending
    case nameDescending

    var title: String {
        switch self {
        case .popularity:
            return "熱門"
        case .nameAscending:
            return "名稱 A-Z"
        case .nameDescending:
            return "名稱 Z-A"
        }
    }

    var systemImageName: String {
        switch self {
        case .popularity:
            return "flame.fill"
        case .nameAscending:
            return "textformat.abc"
        case .nameDescending:
            return "textformat.abc.dottedunderline"
        }
    }
}

struct CharacterListResponse: Codable, Sendable {
    let pagination: CharacterListPagination?
    let data: [CharacterListDTO]
}

struct CharacterListPagination: Codable, Hashable, Sendable {
    let currentPage: Int?
    let hasNextPage: Bool?
    let lastVisiblePage: Int?
}

struct CharacterListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nameKanji: String?
    let nicknames: [String]?
    let favorites: Int?

    var id: Int { malId }
}

struct CharacterListRow: Identifiable, Hashable, Sendable {
    let id: Int
    let malId: Int
    let name: String
    let imageURL: URL?
    let malPageURL: URL?
    let favorites: Int?
    let sortTitle: String

    static func from(_ dto: CharacterListDTO) -> CharacterListRow {
        let displayName = displayName(japanese: dto.nameKanji, fallback: dto.name)

        return CharacterListRow(
            id: dto.malId,
            malId: dto.malId,
            name: displayName,
            imageURL: posterURL(from: dto.images),
            malPageURL: malPageURL(from: dto.url, malId: dto.malId),
            favorites: dto.favorites,
            sortTitle: normalizedSortTitle(from: displayName)
        )
    }

    private static func displayName(japanese: String?, fallback: String?) -> String {
        let candidates = [japanese, fallback]
        for candidate in candidates {
            if let text = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                return text
            }
        }
        return "—"
    }

    private static func malPageURL(from urlString: String?, malId: Int) -> URL? {
        if let urlString, let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://myanimelist.net/character/\(malId)")
    }

    private static func posterURL(from images: AnimeImagesDTO?) -> URL? {
        let webp = images?.webp
        let jpg = images?.jpg
        let candidates: [String?] = [
            webp?.largeImageUrl,
            jpg?.largeImageUrl,
            webp?.imageUrl,
            jpg?.imageUrl,
            jpg?.smallImageUrl,
            webp?.smallImageUrl
        ]
        return candidates.compactMap { $0 }.first.flatMap { URL(string: $0) }
    }

    private static func normalizedSortTitle(from title: String) -> String {
        title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
