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
}
