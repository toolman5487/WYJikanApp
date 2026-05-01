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
    private let apiService: JikanAPIServicing

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
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await apiService.fetch(
            endpoint: APIConfig.Characters.list,
            cachePolicy: .cacheFirst(ttl: 180),
            queryItems: queryItems
        )
    }

    func fetchPeople(page: Int, limit: Int) async throws -> PeopleListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await apiService.fetch(
            endpoint: APIConfig.People.list,
            cachePolicy: .cacheFirst(ttl: 180),
            queryItems: queryItems
        )
    }
}
