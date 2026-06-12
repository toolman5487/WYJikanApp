//
//  AnimeDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Foundation

nonisolated protocol AnimeDetailServicing: Sendable {
    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse
    func fetchAnimePictures(malId: Int) async throws -> AnimePicturesResponse
    func fetchAnimeCharacters(malId: Int) async throws -> AnimeCharactersResponse
    func fetchAnimeRecommendations(malId: Int) async throws -> AnimeRecommendationsResponse
    func fetchAnimeEpisodes(malId: Int, page: Int) async throws -> AnimeEpisodesResponse
    func fetchAnimeEpisodeDetail(malId: Int, episodeNumber: Int) async throws -> AnimeEpisodeDetailResponse
}

nonisolated final class AnimeDetailService: AnimeDetailServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.detail(id: malId),
            cachePolicy: .detail()
        )
    }

    func fetchAnimePictures(malId: Int) async throws -> AnimePicturesResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.pictures(id: malId),
            cachePolicy: .detail()
        )
    }

    func fetchAnimeCharacters(malId: Int) async throws -> AnimeCharactersResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.characters(id: malId),
            cachePolicy: .detail()
        )
    }

    func fetchAnimeRecommendations(malId: Int) async throws -> AnimeRecommendationsResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.recommendations(id: malId),
            cachePolicy: .detail()
        )
    }

    func fetchAnimeEpisodes(malId: Int, page: Int) async throws -> AnimeEpisodesResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.episodes(id: malId),
            cachePolicy: .detail(),
            queryItems: [
                URLQueryItem(name: "page", value: String(page))
            ]
        )
    }

    func fetchAnimeEpisodeDetail(malId: Int, episodeNumber: Int) async throws -> AnimeEpisodeDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.episodeDetail(id: malId, episode: episodeNumber),
            cachePolicy: .detail()
        )
    }
}
