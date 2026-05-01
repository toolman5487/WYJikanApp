//
//  MainSearchService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import Foundation

protocol MainSearchServicing {
    func search(kind: MainSearchKind, query: String, limit: Int) async throws -> [MainSearchResultRow]
}

final class MainSearchService: MainSearchServicing {

    // MARK: - SearchRequestSpec
    
    private let apiService: JikanAPIServicing

    private enum SearchRequestSpec {
        case anime(queryItems: [URLQueryItem])
        case manga(queryItems: [URLQueryItem])
        case character(queryItems: [URLQueryItem])
        case people(queryItems: [URLQueryItem])

        init(kind: MainSearchKind, queryItems: [URLQueryItem]) {
            switch kind {
            case .anime:
                self = .anime(queryItems: queryItems)
            case .manga:
                self = .manga(queryItems: queryItems)
            case .character:
                self = .character(queryItems: queryItems)
            case .people:
                self = .people(queryItems: queryItems)
            }
        }

        var endpoint: String {
            switch self {
            case .anime:
                return APIConfig.Anime.list
            case .manga:
                return APIConfig.Manga.list
            case .character:
                return APIConfig.Characters.list
            case .people:
                return APIConfig.People.list
            }
        }

        var queryItems: [URLQueryItem] {
            switch self {
            case .anime(let queryItems),
                 .manga(let queryItems),
                 .character(let queryItems),
                 .people(let queryItems):
                return queryItems
            }
        }

        var cachePolicy: JikanAPICachePolicy {
            switch self {
            case .anime, .manga, .character, .people:
                return .cacheFirst(ttl: 45)
            }
        }
    }

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func search(kind: MainSearchKind, query: String, limit: Int) async throws -> [MainSearchResultRow] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sfw", value: "true")
        ]

        let request = SearchRequestSpec(kind: kind, queryItems: queryItems)

        switch request {
        case .anime:
            let response: MainSearchAnimeSearchResponse = try await apiService.fetch(
                endpoint: request.endpoint,
                cachePolicy: request.cachePolicy,
                queryItems: request.queryItems
            )
            return response.data.map { MainSearchResultRow.from(anime: $0) }
        case .manga:
            let response: MainSearchMangaSearchResponse = try await apiService.fetch(
                endpoint: request.endpoint,
                cachePolicy: request.cachePolicy,
                queryItems: request.queryItems
            )
            return response.data.map { MainSearchResultRow.from(manga: $0) }
        case .character:
            let response: MainSearchCharacterSearchResponse = try await apiService.fetch(
                endpoint: request.endpoint,
                cachePolicy: request.cachePolicy,
                queryItems: request.queryItems
            )
            return response.data.map { MainSearchResultRow.from(character: $0) }
        case .people:
            let response: MainSearchPersonSearchResponse = try await apiService.fetch(
                endpoint: request.endpoint,
                cachePolicy: request.cachePolicy,
                queryItems: request.queryItems
            )
            return response.data.map { MainSearchResultRow.from(person: $0) }
        }
    }
}
