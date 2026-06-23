//
//  RandomPickService.swift
//  WYJikanApp
//

import Foundation

nonisolated protocol RandomPickServicing: Sendable {
    func fetchRandomAnime() async throws -> AnimeListRandomResponse
    func fetchRandomManga() async throws -> MangaListRandomResponse
}

nonisolated final class RandomPickService: RandomPickServicing {

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
}
