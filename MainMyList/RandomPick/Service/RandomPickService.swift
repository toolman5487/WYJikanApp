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
    private let animeLifecycleScope: RequestLifecycleScope
    private let mangaLifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing,
        animeLifecycleScope: RequestLifecycleScope,
        mangaLifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.animeLifecycleScope = animeLifecycleScope
        self.mangaLifecycleScope = mangaLifecycleScope
    }

    func fetchRandomAnime() async throws -> AnimeListRandomResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Random.anime,
            cachePolicy: .remoteOnly,
            lifecycleScope: animeLifecycleScope
        )
    }

    func fetchRandomManga() async throws -> MangaListRandomResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Random.manga,
            cachePolicy: .remoteOnly,
            lifecycleScope: mangaLifecycleScope
        )
    }
}
