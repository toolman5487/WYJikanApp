//
//  MainSearchModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

// MARK: - Search Kind

enum MainSearchKind: String, CaseIterable, Hashable, Sendable {
    case anime
    case manga
    case character
    case people

    var title: String {
        switch self {
        case .anime: return "動畫"
        case .manga: return "漫畫"
        case .character: return "角色"
        case .people: return "聲優"
        }
    }

    var searchPrompt: String {
        switch self {
        case .anime: return "搜尋動畫"
        case .manga: return "搜尋漫畫"
        case .character: return "搜尋角色"
        case .people: return "搜尋聲優"
        }
    }

    var jikanSearchPath: String {
        switch self {
        case .anime: return "anime"
        case .manga: return "manga"
        case .character: return "characters"
        case .people: return "people"
        }
    }
}

// MARK: - Search Sort

enum MainSearchSortOption: String, CaseIterable, Hashable, Sendable {
    case `default`
    case titleAscending
    case titleDescending
    case newest
    case oldest
    case popularityDescending
    case popularityAscending

    var title: String {
        switch self {
        case .default: return "預設"
        case .titleAscending: return "名稱 A-Z"
        case .titleDescending: return "名稱 Z-A"
        case .newest: return "年份新到舊"
        case .oldest: return "年份舊到新"
        case .popularityDescending: return "人氣高到低"
        case .popularityAscending: return "人氣低到高"
        }
    }

    var systemImageName: String {
        switch self {
        case .default: return "line.3.horizontal.decrease.circle"
        case .titleAscending: return "textformat.abc"
        case .titleDescending: return "textformat.abc.dottedunderline"
        case .newest: return "arrow.down.to.line.compact"
        case .oldest: return "arrow.up.to.line.compact"
        case .popularityDescending: return "flame.fill"
        case .popularityAscending: return "flame"
        }
    }

    static func supportedOptions(for kind: MainSearchKind) -> [MainSearchSortOption] {
        switch kind {
        case .anime, .manga:
            return [.default, .titleAscending, .titleDescending, .newest, .oldest, .popularityDescending, .popularityAscending]
        case .character, .people:
            return [.default, .titleAscending, .titleDescending, .popularityDescending, .popularityAscending]
        }
    }
}

// MARK: - API

// MARK: Pagination

struct MainSearchPaginationDTO: Codable, Hashable, Sendable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?
    let currentPage: Int?
}

// MARK: List Item DTOs

struct MainSearchAnimeListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let year: Int?
    let favorites: Int?
    let members: Int?

    var id: Int { malId }
}

struct MainSearchMangaListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let title: String?
    let titleEnglish: String?
    let titleJapanese: String?
    let type: String?
    let year: Int?
    let favorites: Int?
    let members: Int?

    var id: Int { malId }
}

struct MainSearchCharacterListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nicknames: [String]?
    let favorites: Int?

    var id: Int { malId }
}

struct MainSearchPersonListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let favorites: Int?

    var id: Int { malId }
}

// MARK: Search Responses

struct MainSearchAnimeSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchAnimeListDTO]
}

struct MainSearchMangaSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchMangaListDTO]
}

struct MainSearchCharacterSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchCharacterListDTO]
}

struct MainSearchPersonSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchPersonListDTO]
}

struct MainSearchPage: Sendable {
    let rows: [MainSearchResultRow]
    let currentPage: Int
    let hasNextPage: Bool
}

// MARK: - Result Row

struct MainSearchResultRow: Identifiable, Hashable, Sendable {
    let id: String
    let malId: Int
    let kind: MainSearchKind
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let malPageURL: URL?
    let sortTitle: String
    let year: Int?
    let popularityScore: Int?

    // MARK: Shared Mapping

    static func posterURL(from images: AnimeImagesDTO?) -> URL? {
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
        let urlString = candidates.compactMap { $0 }.first
        guard let urlString else { return nil }
        return URL(string: urlString)
    }

    // MARK: Factory Methods

    static func from(anime dto: MainSearchAnimeListDTO) -> MainSearchResultRow {
        let title = Self.displayWorkTitle(
            japanese: dto.titleJapanese,
            english: dto.titleEnglish,
            fallback: dto.title
        )
        var parts: [String] = []
        if let type = dto.type, !type.isEmpty { parts.append(type) }
        if let year = dto.year { parts.append(String(year)) }
        let subtitle = parts.isEmpty ? nil : parts.joined(separator: " · ")
        return MainSearchResultRow(
            id: "anime-\(dto.malId)",
            malId: dto.malId,
            kind: .anime,
            title: title,
            subtitle: subtitle,
            imageURL: posterURL(from: dto.images),
            malPageURL: dto.url.flatMap { URL(string: $0) },
            sortTitle: normalizedSortTitle(from: title),
            year: dto.year,
            popularityScore: popularityScore(favorites: dto.favorites, members: dto.members)
        )
    }

    static func from(manga dto: MainSearchMangaListDTO) -> MainSearchResultRow {
        let title = Self.displayWorkTitle(
            japanese: dto.titleJapanese,
            english: dto.titleEnglish,
            fallback: dto.title
        )
        var parts: [String] = []
        if let type = dto.type, !type.isEmpty { parts.append(type) }
        if let year = dto.year { parts.append(String(year)) }
        let subtitle = parts.isEmpty ? nil : parts.joined(separator: " · ")
        return MainSearchResultRow(
            id: "manga-\(dto.malId)",
            malId: dto.malId,
            kind: .manga,
            title: title,
            subtitle: subtitle,
            imageURL: posterURL(from: dto.images),
            malPageURL: dto.url.flatMap { URL(string: $0) },
            sortTitle: normalizedSortTitle(from: title),
            year: dto.year,
            popularityScore: popularityScore(favorites: dto.favorites, members: dto.members)
        )
    }

    static func from(character dto: MainSearchCharacterListDTO) -> MainSearchResultRow {
        let title = Self.displayTitle(primary: dto.name, alternate: nil)
        let subtitle = dto.nicknames?.first { !$0.isEmpty }
        return MainSearchResultRow(
            id: "character-\(dto.malId)",
            malId: dto.malId,
            kind: .character,
            title: title,
            subtitle: subtitle,
            imageURL: posterURL(from: dto.images),
            malPageURL: dto.url.flatMap { URL(string: $0) },
            sortTitle: normalizedSortTitle(from: title),
            year: nil,
            popularityScore: dto.favorites
        )
    }

    static func from(person dto: MainSearchPersonListDTO) -> MainSearchResultRow {
        let title = Self.displayTitle(primary: dto.name, alternate: nil)
        return MainSearchResultRow(
            id: "people-\(dto.malId)",
            malId: dto.malId,
            kind: .people,
            title: title,
            subtitle: nil,
            imageURL: posterURL(from: dto.images),
            malPageURL: dto.url.flatMap { URL(string: $0) },
            sortTitle: normalizedSortTitle(from: title),
            year: nil,
            popularityScore: dto.favorites
        )
    }

    // MARK: Private

    private static func displayWorkTitle(japanese: String?, english: String?, fallback: String?) -> String {
        if let t = japanese?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = english?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = fallback?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        return "—"
    }

    private static func displayTitle(primary: String?, alternate: String?) -> String {
        if let t = primary?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        if let t = alternate?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
        return "—"
    }

    private static func normalizedSortTitle(from title: String) -> String {
        title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private static func popularityScore(favorites: Int?, members: Int?) -> Int? {
        switch (favorites, members) {
        case let (favorites?, members?):
            return max(favorites, members)
        case let (favorites?, nil):
            return favorites
        case let (nil, members?):
            return members
        case (nil, nil):
            return nil
        }
    }
}

// MARK: - Screen State

enum MainSearchScreenState: Equatable {
    case emptyPrompt
    case loading
    case error(String)
    case emptyResults(query: String)
    case content([MainSearchResultRow])

    static func resolve(
        trimmedQuery: String,
        query: String,
        isLoading: Bool,
        errorMessage: String?,
        rows: [MainSearchResultRow]
    ) -> MainSearchScreenState {
        if trimmedQuery.isEmpty { return .emptyPrompt }
        if isLoading, rows.isEmpty { return .loading }
        if let message = errorMessage, rows.isEmpty { return .error(message) }
        if rows.isEmpty { return .emptyResults(query: query) }
        return .content(rows)
    }
}
