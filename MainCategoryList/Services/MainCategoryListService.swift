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
}

final class MainCategoryListService: MainCategoryListServicing {
    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchRandomAnime() async throws -> AnimeListRandomResponse {
        try await apiService.fetch(endpoint: APIConfig.Random.anime)
    }

    func fetchRandomManga() async throws -> MangaListRandomResponse {
        try await apiService.fetch(endpoint: APIConfig.Random.manga)
    }

    func fetchAnimeGenres() async throws -> AnimeGenreListResponse {
        try await apiService.fetch(endpoint: APIConfig.Genres.anime)
    }

    func fetchMangaGenres() async throws -> MangaGenreListResponse {
        try await apiService.fetch(endpoint: APIConfig.Genres.manga)
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
}
