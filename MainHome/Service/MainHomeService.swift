//
//  MainHomeService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

protocol MainHomeServicing {
    func fetchHeroBanner() async throws -> HeroBannerResponse
    func fetchTopAnime(limit: Int) async throws -> HomeTrendingAnimeResponse
    func fetchTopManga(limit: Int) async throws -> HomeTrendingMangaResponse
}

final class MainHomeService: MainHomeServicing {

    private let apiService: JikanAPIService

    init(apiService: JikanAPIService = .shared) {
        self.apiService = apiService
    }

    func fetchHeroBanner() async throws -> HeroBannerResponse {
        try await apiService.fetch(endpoint: APIConfig.Seasons.now())
    }

    func fetchTopAnime(limit: Int) async throws -> HomeTrendingAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.anime,
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }
    
    func fetchTopManga(limit: Int) async throws -> HomeTrendingMangaResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.manga,
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }
}

