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

    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse {
        try await apiService.fetch(endpoint: APIConfig.Anime.detail(id: malId))
    }

    func fetchAnimePictures(malId: Int) async throws -> AnimePicturesResponse {
        try await apiService.fetch(endpoint: APIConfig.Anime.pictures(id: malId))
    }
}
