//
//  AnimeDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

protocol AnimeDetailServicing {
    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse
    func fetchAnimePictures(malId: Int) async throws -> AnimePicturesResponse
    func fetchAnimeCharacters(malId: Int) async throws -> AnimeCharactersResponse
    func fetchAnimeRecommendations(malId: Int) async throws -> AnimeRecommendationsResponse
    func fetchAnimeEpisodes(malId: Int, page: Int) async throws -> AnimeEpisodesResponse
}

final class AnimeDetailService: AnimeDetailServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.detail(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchAnimePictures(malId: Int) async throws -> AnimePicturesResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.pictures(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchAnimeCharacters(malId: Int) async throws -> AnimeCharactersResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.characters(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchAnimeRecommendations(malId: Int) async throws -> AnimeRecommendationsResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.recommendations(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchAnimeEpisodes(malId: Int, page: Int) async throws -> AnimeEpisodesResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.episodes(id: malId),
            cachePolicy: .cacheFirst(ttl: 600),
            queryItems: [
                URLQueryItem(name: "page", value: String(page))
            ]
        )
    }
}
