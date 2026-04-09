//
//  MainCategoryListService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation

protocol MainCategoryListServicing {
    func fetchRandomAnime() async throws -> AnimeListRandomResponse
    func fetchAnimeGenres() async throws -> AnimeGenreListResponse
    func fetchAnimeByGenre(genreId: Int, limit: Int) async throws -> AnimeListResponse
}

final class MainCategoryListService: MainCategoryListServicing {
    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchRandomAnime() async throws -> AnimeListRandomResponse {
        try await apiService.fetch(endpoint: APIConfig.Random.anime)
    }

    func fetchAnimeGenres() async throws -> AnimeGenreListResponse {
        try await apiService.fetch(endpoint: APIConfig.Genres.anime)
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
}
