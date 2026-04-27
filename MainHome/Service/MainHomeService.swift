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

    func fetchTodayAnime(limit: Int) async throws -> HomeTodayAnimeResponse {
        let weekday = Self.currentWeekdayForAPI()
        return try await apiService.fetch(
            endpoint: APIConfig.Schedules.day(weekday),
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
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }

    func fetchAnimeDetail(malId: Int) async throws -> AnimeDetailResponse {
        try await apiService.fetch(endpoint: APIConfig.Anime.detail(id: malId))
    }

    private static func currentWeekdayForAPI() -> String {
        let weekdayIndex = Calendar.current.component(.weekday, from: Date())
        switch weekdayIndex {
        case 1: return "sunday"
        case 2: return "monday"
        case 3: return "tuesday"
        case 4: return "wednesday"
        case 5: return "thursday"
        case 6: return "friday"
        case 7: return "saturday"
        default: return "monday"
        }
    }
}
