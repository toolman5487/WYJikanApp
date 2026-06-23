//
//  MainHomeService.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/25.
//

import Foundation

// MARK: - MainHomeServicing

nonisolated protocol MainHomeServicing: Sendable {
    func fetchHeroBanner(forceRefresh: Bool) async throws -> HeroBannerResponse
    func fetchTopAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingAnimeResponse
    func fetchTopManga(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingMangaResponse
    func fetchTodayAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTodayAnimeResponse
    func fetchRecommendedAnime(limit: Int, forceRefresh: Bool) async throws -> HomeRecommendedAnimeResponse
    func fetchAnimeDetail(malId: Int, forceRefresh: Bool) async throws -> AnimeDetailResponse
}

// MARK: - MainHomeServicing Default Implementation

nonisolated extension MainHomeServicing {
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

// MARK: - MainHomeService

nonisolated final class MainHomeService: MainHomeServicing {

    // MARK: - Properties

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    // MARK: - Lifecycle

    init(
        apiService: JikanAPIServicing = JikanAPIService.shared,
        lifecycleScope: RequestLifecycleScope = .tab(.home)
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    // MARK: - Public Methods

    func fetchHeroBanner(forceRefresh: Bool) async throws -> HeroBannerResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Seasons.now(),
            cachePolicy: .feed(forceRefresh: forceRefresh),
            lifecycleScope: lifecycleScope
        )
    }

    func fetchTopAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.anime,
            cachePolicy: .feed(forceRefresh: forceRefresh),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ],
            lifecycleScope: lifecycleScope
        )
    }

    func fetchTopManga(limit: Int, forceRefresh: Bool) async throws -> HomeTrendingMangaResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.manga,
            cachePolicy: .feed(forceRefresh: forceRefresh),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ],
            lifecycleScope: lifecycleScope
        )
    }

    func fetchTodayAnime(limit: Int, forceRefresh: Bool) async throws -> HomeTodayAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Schedules.day(HomeScheduleDay.current().apiValue),
            cachePolicy: .feed(forceRefresh: forceRefresh),
            queryItems: [
                URLQueryItem(name: "filter", value: "tv"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "sfw", value: "true")
            ],
            lifecycleScope: lifecycleScope
        )
    }

    func fetchRecommendedAnime(limit: Int, forceRefresh: Bool) async throws -> HomeRecommendedAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Recommendations.anime,
            cachePolicy: .feed(forceRefresh: forceRefresh),
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ],
            lifecycleScope: lifecycleScope
        )
    }

    func fetchAnimeDetail(malId: Int, forceRefresh: Bool) async throws -> AnimeDetailResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Anime.detail(id: malId),
            cachePolicy: .detail(forceRefresh: forceRefresh),
            lifecycleScope: lifecycleScope
        )
    }
}
