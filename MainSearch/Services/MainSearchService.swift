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

    private let apiService: JikanAPIServicing

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

        switch kind {
        case .anime:
            let response: MainSearchAnimeSearchResponse = try await apiService.fetch(
                endpoint: APIConfig.Anime.list,
                queryItems: queryItems
            )
            return response.data.map { MainSearchResultRow.from(anime: $0) }
        case .manga:
            let response: MainSearchMangaSearchResponse = try await apiService.fetch(
                endpoint: APIConfig.Manga.list,
                queryItems: queryItems
            )
            return response.data.map { MainSearchResultRow.from(manga: $0) }
        case .character:
            let response: MainSearchCharacterSearchResponse = try await apiService.fetch(
                endpoint: APIConfig.Characters.list,
                queryItems: queryItems
            )
            return response.data.map { MainSearchResultRow.from(character: $0) }
        case .people:
            let response: MainSearchPersonSearchResponse = try await apiService.fetch(
                endpoint: APIConfig.People.list,
                queryItems: queryItems
            )
            return response.data.map { MainSearchResultRow.from(person: $0) }
        }
    }
}
