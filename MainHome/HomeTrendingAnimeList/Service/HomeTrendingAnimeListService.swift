//
//  HomeTrendingAnimeListService.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import Foundation

protocol HomeTrendingAnimeListServicing {
    func fetchPage(page: Int, limit: Int) async throws -> HomeTrendingAnimeListResponse
}

final class HomeTrendingAnimeListService: HomeTrendingAnimeListServicing {
    private let apiService: JikanAPIServicing

    init(apiService: JikanAPIServicing = JikanAPIService.shared) {
        self.apiService = apiService
    }

    func fetchPage(page: Int, limit: Int) async throws -> HomeTrendingAnimeListResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.anime,
            cachePolicy: .cacheFirst(ttl: 300),
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
    }
}
