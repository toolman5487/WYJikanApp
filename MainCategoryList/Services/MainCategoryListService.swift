//
//  MainCategoryListService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation

nonisolated protocol MainCategoryListServicing: Sendable {
    func fetchAnimeGenres() async throws -> AnimeGenreListResponse
    func fetchMangaGenres() async throws -> MangaGenreListResponse
    func fetchAnimeByGenre(genreId: Int, limit: Int) async throws -> AnimeListResponse
    func fetchMangaByGenre(genreId: Int, limit: Int) async throws -> MangaListResponse
    func fetchCharacters(page: Int, limit: Int) async throws -> CharacterListResponse
    func fetchPeople(page: Int, limit: Int) async throws -> PeopleListResponse
}

nonisolated final class MainCategoryListService: MainCategoryListServicing {

    // MARK: - PaginatedListRequest
    
    private let apiService: JikanAPIServicing

    private enum PaginatedListRequest {
        case characters(page: Int, limit: Int)
        case people(page: Int, limit: Int)

        var endpoint: String {
            switch self {
            case .characters:
                return APIConfig.Characters.list
            case .people:
                return APIConfig.Top.people
            }
        }

        var queryItems: [URLQueryItem] {
            let page: Int
            let limit: Int

            switch self {
            case .characters(let requestPage, let requestLimit),
                 .people(let requestPage, let requestLimit):
                page = requestPage
                limit = requestLimit
            }

            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }

        var cachePolicy: JikanAPICachePolicy {
            let page: Int

            switch self {
            case .characters(let requestPage, _),
                 .people(let requestPage, _):
                page = requestPage
            }

            return .paging(page: page)
        }
    }


    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchAnimeGenres() async throws -> AnimeGenreListResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Genres.anime,
            cachePolicy: .genreList(),
            lifecycleScope: .mainCategoryList
        )
    }

    func fetchMangaGenres() async throws -> MangaGenreListResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Genres.manga,
            cachePolicy: .genreList(),
            lifecycleScope: .mainCategoryList
        )
    }

    func fetchAnimeByGenre(genreId: Int, limit: Int) async throws -> AnimeListResponse {
        let queryItems = [
            URLQueryItem(name: "genres", value: "\(genreId)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await apiService.fetch(
            endpoint: APIConfig.Anime.list,
            cachePolicy: .cacheFirst(ttl: JikanCacheDuration.genreItems),
            queryItems: queryItems,
            lifecycleScope: .mainCategoryList
        )
    }

    func fetchMangaByGenre(genreId: Int, limit: Int) async throws -> MangaListResponse {
        let queryItems = [
            URLQueryItem(name: "genres", value: "\(genreId)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await apiService.fetch(
            endpoint: APIConfig.Manga.list,
            cachePolicy: .cacheFirst(ttl: JikanCacheDuration.genreItems),
            queryItems: queryItems,
            lifecycleScope: .mainCategoryList
        )
    }

    func fetchCharacters(page: Int, limit: Int) async throws -> CharacterListResponse {
        let request = PaginatedListRequest.characters(page: page, limit: limit)
        return try await apiService.fetch(
            endpoint: request.endpoint,
            cachePolicy: request.cachePolicy,
            queryItems: request.queryItems,
            lifecycleScope: .mainCategoryList
        )
    }

    func fetchPeople(page: Int, limit: Int) async throws -> PeopleListResponse {
        let request = PaginatedListRequest.people(page: page, limit: limit)
        return try await apiService.fetch(
            endpoint: request.endpoint,
            cachePolicy: request.cachePolicy,
            queryItems: request.queryItems,
            lifecycleScope: .mainCategoryList
        )
    }
}
