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
    func fetchTodayAnime(limit: Int) async throws -> HomeTodayAnimeResponse
    func fetchRecommendedAnime(limit: Int) async throws -> HomeRecommendedAnimeResponse
    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse
}

final class MainHomeService: MainHomeServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchHeroBanner() async throws -> HeroBannerResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Seasons.now(),
            cachePolicy: .cacheFirst(ttl: 300)
        )
    }

    func fetchTopAnime(limit: Int) async throws -> HomeTrendingAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.anime,
            cachePolicy: .cacheFirst(ttl: 300),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }
    
    func fetchTopManga(limit: Int) async throws -> HomeTrendingMangaResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.manga,
            cachePolicy: .cacheFirst(ttl: 300),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    func fetchTodayAnime(limit: Int) async throws -> HomeTodayAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Schedules.day(HomeScheduleDay.current().apiValue),
            cachePolicy: .cacheFirst(ttl: 300),
            queryItems: [
                URLQueryItem(name: "filter", value: "tv"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "sfw", value: "true")
            ]
        )
    }

    func fetchRecommendedAnime(limit: Int) async throws -> HomeRecommendedAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Recommendations.anime,
            cachePolicy: .cacheFirst(ttl: 300),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.detail(id: malId),
            cachePolicy: .cacheFirst(ttl: 600)
        )
    }

}
