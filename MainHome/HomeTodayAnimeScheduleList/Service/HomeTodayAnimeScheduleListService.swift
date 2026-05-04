//
//  HomeTodayAnimeScheduleListService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import Foundation

protocol HomeTodayAnimeScheduleListServicing {
    func fetchSchedulePage(
        day: HomeScheduleDay,
        page: Int,
        limit: Int
    ) async throws -> HomeTodayAnimeResponse
}

final class HomeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListServicing {
    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchSchedulePage(
        day: HomeScheduleDay,
        page: Int,
        limit: Int
    ) async throws -> HomeTodayAnimeResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Schedules.day(day.apiValue),
            cachePolicy: .cacheFirst(ttl: 300),
            queryItems: [
                URLQueryItem(name: "filter", value: "tv"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "sfw", value: "true")
            ]
        )
    }
}
