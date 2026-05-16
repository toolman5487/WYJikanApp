//
//  MainHomeService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

protocol MainHomeServicing {
    func fetchHeroBanner(forceRefresh: Bool) async throws -> HeroBannerResponse
    func fetchTopAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingAnimeResponse
    func fetchTopManga(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingMangaResponse
    func fetchTodayAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTodayAnimeResponse
    func fetchRecommendedAnime(limit: Int, forceRefresh: Bool) async throws -> HomeRecommendedAnimeResponse
    func fetchAnimeDetail(malId: Int, forceRefresh: Bool) async throws -> AnimeDetailResponse
}

extension MainHomeServicing {
    func fetchHeroBanner() async throws -> HeroBannerResponse {
        try await fetchHeroBanner(forceRefresh: false)
    }

    func fetchTopAnime(limit: Int) async throws -> HomeTrendingAnimeResponse {
        try await fetchTopAnime(limit: limit, forceRefresh: false)
    }

    func fetchTopManga(limit: Int) async throws -> HomeTrendingMangaResponse {
        try await fetchTopManga(limit: limit, forceRefresh: false)
    }

    func fetchTodayAnime(limit: Int) async throws -> HomeTodayAnimeResponse {
        try await fetchTodayAnime(limit: limit, forceRefresh: false)
    }

    func fetchRecommendedAnime(limit: Int) async throws -> HomeRecommendedAnimeResponse {
        try await fetchRecommendedAnime(limit: limit, forceRefresh: false)
    }

    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse {
        try await fetchAnimeDetail(malId: malId, forceRefresh: false)
    }
}

final class MainHomeService: MainHomeServicing {

    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchHeroBanner(forceRefresh: Bool) async throws -> HeroBannerResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Seasons.now(),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: 300)
        )
    }

    func fetchTopAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.anime,
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: 300),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }
    
    func fetchTopManga(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingMangaResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.manga,
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: 300),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    func fetchTodayAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTodayAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Schedules.day(HomeScheduleDay.current().apiValue),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: 300),
            queryItems: [
                URLQueryItem(name: "filter", value: "tv"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "sfw", value: "true")
            ]
        )
    }

    func fetchRecommendedAnime(limit: Int, forceRefresh: Bool) async throws -> HomeRecommendedAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Recommendations.anime,
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: 300),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    func fetchAnimeDetail(malId: Int, forceRefresh: Bool) async throws -> AnimeDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.detail(id: malId),
            cachePolicy: cachePolicy(forceRefresh: forceRefresh, ttl: 600)
        )
    }

    private func cachePolicy(forceRefresh: Bool, ttl: TimeInterval) -> JikanAPICachePolicy {
        forceRefresh ? .remoteOnly : .cacheFirst(ttl: ttl)
    }

}
