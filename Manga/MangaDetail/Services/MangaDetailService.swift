//
//  MangaDetailService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Foundation

protocol MangaDetailServicing {
    func fetchMangaDetail(malId: Int) async throws -> MangaDetailResponse
    func fetchMangaPictures(malId: Int) async throws -> MangaPicturesResponse
    func fetchMangaCharacters(malId: Int) async throws -> MangaCharactersResponse
    func fetchMangaRecommendations(malId: Int) async throws -> MangaRecommendationsResponse
}

final class MangaDetailService: MangaDetailServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchMangaDetail(malId: Int) async throws -> MangaDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.detail(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchMangaPictures(malId: Int) async throws -> MangaPicturesResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.pictures(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchMangaCharacters(malId: Int) async throws -> MangaCharactersResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.characters(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

    func fetchMangaRecommendations(malId: Int) async throws -> MangaRecommendationsResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Manga.recommendations(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }
}
