//
//  HomeTrendingAnimeListService.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/5/5.
//

import Foundation

// MARK: - HomeTrendingAnimeListServicing

nonisolated protocol HomeTrendingAnimeListServicing: Sendable {
    func fetchPage(page: Int, limit: Int) async throws -> HomeTrendingAnimeListResponse
}

// MARK: - HomeTrendingAnimeListService

nonisolated final class HomeTrendingAnimeListService: HomeTrendingAnimeListServicing {

    // MARK: - Properties

    private let apiService: JikanAPIServicing
    private let lifecycleScope: RequestLifecycleScope

    // MARK: - Lifecycle

    init(
        apiService: JikanAPIServicing,
        lifecycleScope: RequestLifecycleScope
    ) {
        self.apiService = apiService
        self.lifecycleScope = lifecycleScope
    }

    // MARK: - Public Methods

    func fetchPage(page: Int, limit: Int) async throws -> HomeTrendingAnimeListResponse {
        try await apiService.fetch(
            endpoint: APIConfig.Top.anime,
            cachePolicy: .paging(page: page),
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ],
            lifecycleScope: lifecycleScope
        )
    }
}
