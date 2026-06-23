//
//  MainSearchModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

// MARK: - Search Kind

nonisolated enum MainSearchKind: String, CaseIterable, Codable, Hashable, Sendable {
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

nonisolated enum MainSearchSortOption: String, CaseIterable, Hashable, Sendable {
    case defaultOption
    case titleAscending
    case titleDescending
    case newest
    case oldest
    case popularityDescending
    case popularityAscending

    var title: String {
        switch self {
        case .defaultOption: return "預設"
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
        case .defaultOption: return "line.3.horizontal.decrease.circle"
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
        case .anime:
            return [
                .defaultOption,
                .titleAscending,
                .titleDescending,
                .newest,
                .oldest,
                .popularityDescending,
                .popularityAscending
            ]
        case .manga:
            return [
                .defaultOption,
                .titleAscending,
                .titleDescending,
                .newest,
                .oldest,
                .popularityDescending,
                .popularityAscending
            ]
        case .character:
            return [
                .defaultOption,
                .titleAscending,
                .titleDescending,
                .popularityDescending,
                .popularityAscending
            ]
        case .people:
            return [
                .defaultOption,
                .titleAscending,
                .titleDescending,
                .popularityDescending,
                .popularityAscending
            ]
        }
    }
}

// MARK: - API

// MARK: - Pagination

nonisolated struct MainSearchPaginationDTO: Codable, Hashable, Sendable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?
    let currentPage: Int?
}

// MARK: - List Item DTOs

nonisolated struct MainSearchAnimeListDTO: Codable, Identifiable, Hashable, Sendable {
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

nonisolated struct MainSearchMangaListDTO: Codable, Identifiable, Hashable, Sendable {
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

nonisolated struct MainSearchCharacterListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nicknames: [String]?
    let favorites: Int?

    var id: Int { malId }
}

nonisolated struct MainSearchPersonListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let favorites: Int?

    var id: Int { malId }
}

// MARK: - Search Responses

nonisolated struct MainSearchAnimeSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchAnimeListDTO]
}

nonisolated struct MainSearchMangaSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchMangaListDTO]
}

nonisolated struct MainSearchCharacterSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchCharacterListDTO]
}

nonisolated struct MainSearchPersonSearchResponse: Codable, Sendable {
    let pagination: MainSearchPaginationDTO?
    let data: [MainSearchPersonListDTO]
}

nonisolated struct MainSearchPage: Sendable {
    let rows: [MainSearchResultRow]
    let currentPage: Int
    let hasNextPage: Bool
}

// MARK: - Search History

nonisolated struct MainSearchHistoryItem: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let query: String
    let kind: MainSearchKind
    let searchedAt: Date

    init(
        id: UUID = UUID(),
        query: String,
        kind: MainSearchKind,
        searchedAt: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.kind = kind
        self.searchedAt = searchedAt
    }
}

// MARK: - Result Row

nonisolated struct MainSearchResultRow: Identifiable, Hashable, Sendable {
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

    // MARK: - Shared Mapping

    static func posterURL(from images: AnimeImagesDTO?) -> URL? {
        JikanImageURLResolver.url(from: images, tier: .card)
    }

    // MARK: - Factory Methods

    static func from(anime dto: MainSearchAnimeListDTO) -> MainSearchResultRow {
        let title = Self.displayWorkTitle(
            japanese: dto.titleJapanese,
            english: dto.titleEnglish,
            fallback: dto.title
        )
        var parts: [String] = []
        if let type = MediaTypeFormatting.localizedName(for: dto.type, kind: .anime) { parts.append(type) }
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
        if let type = MediaTypeFormatting.localizedName(for: dto.type, kind: .manga) { parts.append(type) }
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

    // MARK: - Private Methods

    private static func displayWorkTitle(
        japanese: String?,
        english: String?,
        fallback: String?
    ) -> String {
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
    case error(FeatureLoadFailure)
    case emptyResults(query: String)
    case content([MainSearchResultRow])
}

typealias MainSearchLoadMoreState = PaginationFooterState
