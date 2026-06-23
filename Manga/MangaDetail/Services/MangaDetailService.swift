//
//  MangaDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Foundation

nonisolated protocol MangaDetailServicing: Sendable {
    func fetchMangaDetail(malId: Int) async throws -> MangaDetailResponse
    func fetchMangaPictures(malId: Int) async throws -> MangaPicturesResponse
    func fetchMangaCharacters(malId: Int) async throws -> MangaCharactersResponse
    func fetchMangaRecommendations(malId: Int) async throws -> MangaRecommendationsResponse
}

nonisolated final class MangaDetailService: MangaDetailServicing {

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    init(
        apiService: JikanAPIServicing,
        lifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    func fetchMangaDetail(malId: Int) async throws -> MangaDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.detail(id: malId),
            cachePolicy: .detail(),
            lifecycleScope: lifecycleScope
        )
    }

    func fetchMangaPictures(malId: Int) async throws -> MangaPicturesResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.pictures(id: malId),
            cachePolicy: .detail(),
            lifecycleScope: lifecycleScope
        )
    }

    func fetchMangaCharacters(malId: Int) async throws -> MangaCharactersResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.characters(id: malId),
            cachePolicy: .detail(),
            lifecycleScope: lifecycleScope
        )
    }

    func fetchMangaRecommendations(malId: Int) async throws -> MangaRecommendationsResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.recommendations(id: malId),
            cachePolicy: .detail(),
            lifecycleScope: lifecycleScope
        )
    }
}
