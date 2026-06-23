//
//  HomeTodayAnimeScheduleListService.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/5.
//

import Foundation

// MARK: - HomeTodayAnimeScheduleListServicing

nonisolated protocol HomeTodayAnimeScheduleListServicing: Sendable {
    func fetchSchedulePage(
        day: HomeScheduleDay,
        page: Int,
        limit: Int
    ) async throws -> HomeTodayAnimeResponse
}

// MARK: - HomeTodayAnimeScheduleListService

nonisolated final class HomeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListServicing {

    // MARK: - Properties

    private let apiService: JikanAPIServicing

    // MARK: - Lifecycle

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    // MARK: - Public Methods

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
            ],
            scope: .home
        )
    }
}
