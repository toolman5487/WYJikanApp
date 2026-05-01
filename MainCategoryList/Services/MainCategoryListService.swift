//
//  MainCategoryListService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation

protocol MainCategoryListServicing {
    func fetchRandomAnime() async throws -> AnimeListRandomResponse
    func fetchRandomManga() async throws -> MangaListRandomResponse
    func fetchAnimeGenres() async throws -> AnimeGenreListResponse
    func fetchMangaGenres() async throws -> MangaGenreListResponse
    func fetchAnimeByGenre(genreId: Int, limit: Int) async throws -> AnimeListResponse
    func fetchMangaByGenre(genreId: Int, limit: Int) async throws -> MangaListResponse
    func fetchCharacters(page: Int, limit: Int) async throws -> CharacterListResponse
    func fetchPeople(page: Int, limit: Int) async throws -> PeopleListResponse
}

final class MainCategoryListService: MainCategoryListServicing {

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
                return APIConfig.People.list
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

            switch page {
            case 1:
                return .cacheFirst(ttl: 300)
            default:
                return .cacheFirst(ttl: 120)
            }
        }
    }


    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchRandomAnime() async throws -> AnimeListRandomResponse {
        try await apiService.fetch(endpoint: APIConfig.Random.anime)
    }

    func fetchRandomManga() async throws -> MangaListRandomResponse {
        try await apiService.fetch(endpoint: APIConfig.Random.manga)
    }

    func fetchAnimeGenres() async throws -> AnimeGenreListResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Genres.anime,
            cachePolicy: .cacheFirst(ttl: 86_400)
        )
    }

    func fetchMangaGenres() async throws -> MangaGenreListResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Genres.manga,
            cachePolicy: .cacheFirst(ttl: 86_400)
        )
    }

    func fetchAnimeByGenre(genreId: Int, limit: Int) async throws -> AnimeListResponse {
        let queryItems = [
            URLQueryItem(name: "genres", value: "\(genreId)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await apiService.fetch(
            endpoint: APIConfig.Anime.list,
            queryItems: queryItems
        )
    }

    func fetchMangaByGenre(genreId: Int, limit: Int) async throws -> MangaListResponse {
        let queryItems = [
            URLQueryItem(name: "genres", value: "\(genreId)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await apiService.fetch(
            endpoint: APIConfig.Manga.list,
            queryItems: queryItems
        )
    }

    func fetchCharacters(page: Int, limit: Int) async throws -> CharacterListResponse {
        let request = PaginatedListRequest.characters(page: page, limit: limit)
        return try await apiService.fetch(
            endpoint: request.endpoint,
            cachePolicy: request.cachePolicy,
            queryItems: request.queryItems
        )
    }

    func fetchPeople(page: Int, limit: Int) async throws -> PeopleListResponse {
        let request = PaginatedListRequest.people(page: page, limit: limit)
        return try await apiService.fetch(
            endpoint: request.endpoint,
            cachePolicy: request.cachePolicy,
            queryItems: request.queryItems
        )
    }
}
