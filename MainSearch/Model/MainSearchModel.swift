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

    var id: Int { malId }
}

struct MainSearchCharacterListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?
    let nicknames: [String]?

    var id: Int { malId }
}

struct MainSearchPersonListDTO: Codable, Identifiable, Hashable, Sendable {
    let malId: Int
    let url: String?
    let images: AnimeImagesDTO?
    let name: String?

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

// MARK: - Result Row

struct MainSearchResultRow: Identifiable, Hashable, Sendable {
    let id: String
    let malId: Int
    let kind: MainSearchKind
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let malPageURL: URL?

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
            malPageURL: dto.url.flatMap { URL(string: $0) }
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
            malPageURL: dto.url.flatMap { URL(string: $0) }
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
            malPageURL: dto.url.flatMap { URL(string: $0) }
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
            malPageURL: dto.url.flatMap { URL(string: $0) }
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
